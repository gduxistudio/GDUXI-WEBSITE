#!/usr/bin/env python3
"""Full click-through of the site with Playwright.

Usage:
  python3 -m http.server 8000            # in the site folder
  python3 tests/test_site.py http://localhost:8000/index.html

Set PW_CHROMIUM=/path/to/chrome to use a specific Chromium build.
"""
import json
import os
import sys

from playwright.sync_api import sync_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000/index.html"
FAILS = []


def check(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond:
        FAILS.append(msg)


def visible_page(page):
    return page.evaluate("[...document.querySelectorAll('.page')].find(p=>!p.hidden).dataset.page")


def overflow(page):
    return page.evaluate("document.documentElement.scrollWidth - window.innerWidth")


def a11y_names(page):
    # every visible interactive element needs an accessible name
    return page.evaluate(
        """() => {
        const bad = [];
        const els = [...document.querySelectorAll('a[href],button,input,select,textarea,[role=button],summary')]
          .filter(e => e.offsetParent !== null || e.getClientRects().length);
        for (const e of els) {
          let name = (e.getAttribute('aria-label') || '').trim() || (e.innerText || '').trim();
          if (!name && e.id) { const l = document.querySelector(`label[for="${e.id}"]`); if (l) name = l.innerText.trim(); }
          if (!name && e.closest('label')) name = e.closest('label').innerText.trim();
          if (!name) bad.push(e.outerHTML.slice(0, 80));
        }
        return {count: els.length, bad};
      }"""
    )


def run(p):
    exe = os.environ.get("PW_CHROMIUM")
    browser = p.chromium.launch(**({"executable_path": exe} if exe else {}))
    for width, height, label in [(1440, 900, "desktop"), (390, 844, "phone")]:
        print(f"\n== {label} {width}px ==")
        ctx = browser.new_context(viewport={"width": width, "height": height})
        page = ctx.new_page()
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.on("console", lambda m: m.type == "error" and errors.append(m.text))
        page.route("https://fonts.googleapis.com/**", lambda r: r.fulfill(status=200, body=""))
        page.goto(URL)
        page.wait_for_function("!document.documentElement.classList.contains('cms-loading')")

        # routes and overflow
        for route in ["home", "work", "studio", "services"]:
            page.evaluate(f"location.hash='#{route}'")
            page.wait_for_timeout(250)
            check(visible_page(page) == route, f"#{route} shows the {route} page")
            check(overflow(page) <= 0, f"#{route} has no horizontal overflow ({overflow(page)}px)")
        page.evaluate("location.hash='#contact'")
        page.wait_for_timeout(400)
        check(visible_page(page) == "services", "#contact shows the services page")
        check(page.evaluate("Math.abs(document.querySelector('#contact').getBoundingClientRect().top) < 120"), "#contact scrolls to the form")

        # every data-route link works
        page.evaluate("location.hash='#home'")
        page.wait_for_timeout(200)
        routes = page.evaluate("[...new Set([...document.querySelectorAll('.page:not([hidden]) [data-route], footer [data-route]')].map(a=>a.dataset.route))]")
        for r in routes:
            page.evaluate("location.hash='#home'")
            page.wait_for_timeout(150)
            el = page.locator(f".page:not([hidden]) [data-route='{r}'], footer [data-route='{r}']").first
            el.scroll_into_view_if_needed()
            el.click()
            page.wait_for_timeout(200)
            check(visible_page(page) == ("services" if r == "contact" else r), f"link to {r} works")

        # service cards pre-select the contact form option
        page.evaluate("location.hash='#home'")
        page.wait_for_timeout(200)
        for need in ["n1", "n2", "n3"]:
            page.evaluate("location.hash='#home'")
            page.wait_for_timeout(150)
            page.locator(f".page:not([hidden]) .svc[data-need='{need}']").click()
            page.wait_for_timeout(200)
            check(page.is_checked(f"#{need}"), f"service card pre-selects {need}")

        # filters
        page.evaluate("location.hash='#work'")
        page.wait_for_timeout(250)
        for f, bt, mw, cards in [("bd", True, False, 0), ("dg", False, True, 2), ("id", False, True, 2), ("all", True, True, 4)]:
            page.click(f"[data-filter='{f}']")
            page.wait_for_timeout(150)
            check(page.is_visible("#built-together") == bt and page.is_visible("#more-work") == mw, f"filter {f}: sections")
            n = page.evaluate("[...document.querySelectorAll('#more-grid .proj')].filter(c=>!c.hidden).length")
            if mw:
                check(n == cards, f"filter {f}: {n} more-project cards")
            check(page.get_attribute(f"[data-filter='{f}']", "aria-pressed") == "true", f"filter {f}: aria-pressed")

        # mobile menu
        if width < 900:
            page.click("#burger")
            check(page.is_visible("#mmenu"), "menu opens")
            page.keyboard.press("Escape")
            check(page.is_hidden("#mmenu"), "menu closes on Escape")
            page.click("#burger")
            page.click("#mclose")
            check(page.is_hidden("#mmenu"), "menu closes on ✕")
            page.click("#burger")
            page.click("#mmenu [data-route='studio']")
            check(page.is_hidden("#mmenu") and visible_page(page) == "studio", "menu closes on route click")

        # contact form: validation
        page.evaluate("location.hash='#contact'")
        page.wait_for_timeout(300)
        page.click("#send")
        check(page.inner_text("#e-name") != "" and page.inner_text("#e-email") != "" and page.inner_text("#e-msg") != "", "empty form shows 3 errors")

        def fill():
            page.fill("#name", "Jane Doe")
            page.fill("#email", "jane@example.com")
            page.fill("#message", "We need a logo and a website.")

        # success path
        sent = {}

        def ok(route):
            sent["body"] = json.loads(route.request.post_data)
            route.fulfill(status=200, content_type="application/json", body='{"success":"true"}')

        page.route("https://formsubmit.co/**", ok)
        fill()
        page.click("#send")
        page.wait_for_selector("#sentDlg[open]")
        check(page.is_visible("#sentOk") and "Jane" in page.inner_text("#sentOk"), "success dialog thanks the sender")
        check(sent.get("body", {}).get("_subject") == "New project enquiry from the GDUXI website", "form sends the subject")
        page.click("#sentOk [data-route='home']")
        page.wait_for_timeout(200)
        check(visible_page(page) == "home" and not page.evaluate("document.querySelector('#sentDlg').open"), "Back to home works")
        page.unroute("https://formsubmit.co/**")

        # failure path (FormSubmit before activation)
        page.route("https://formsubmit.co/**", lambda r: r.fulfill(status=200, content_type="application/json", body='{"success":"false","message":"activate"}'))
        page.evaluate("location.hash='#contact'")
        page.wait_for_timeout(300)
        fill()
        page.click("#send")
        page.wait_for_selector("#sentDlg[open]")
        check(page.is_visible("#sentFail"), "unactivated FormSubmit shows the fallback")
        check(page.get_attribute("#failMail", "href").startswith("mailto:gduxistudio@gmail.com?subject="), "fallback has a pre-filled mailto")
        check("mail.google.com" in page.get_attribute("#failGmail", "href"), "fallback has a Gmail link")
        page.click("#sentDlg .x")
        page.unroute("https://formsubmit.co/**")

        # external links
        bad = page.evaluate("[...document.querySelectorAll('a[target=_blank]')].filter(a=>!a.href.startsWith('mailto:') && (a.rel!=='noopener noreferrer' || !a.querySelector('.sr-only'))).map(a=>a.href)")
        check(not bad, f"new-tab links have rel and an sr-only note {bad[:3]}")

        # accessibility names on each page
        total = 0
        for route in ["home", "work", "studio", "services"]:
            page.evaluate(f"location.hash='#{route}'")
            page.wait_for_timeout(200)
            r = a11y_names(page)
            total += r["count"]
            check(not r["bad"], f"{route}: {r['count']} interactive elements all named {r['bad'][:2]}")
        print(f"  {total} interactive elements checked")
        check(not errors, f"no JS errors {errors[:3]}")
        ctx.close()
    browser.close()


with sync_playwright() as p:
    run(p)
print(f"\n{'ALL PASSED' if not FAILS else str(len(FAILS)) + ' FAILED'}")
sys.exit(1 if FAILS else 0)
