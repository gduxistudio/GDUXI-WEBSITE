#!/usr/bin/env python3
"""The phone's back button (and the browser's) closes pop-ups instead of leaving the site,
and leaves the page at the same scroll spot. Closing with the ✕ keeps history in sync:
the next back goes to the previous page, not to a dead entry.

Usage: python3 tests/test_back_button.py http://localhost:8000/index.html
"""
import os
import sys

from playwright.sync_api import sync_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000/index.html"
FAILS = []


def check(ok, msg):
    print(("PASS " if ok else "FAIL ") + msg)
    if not ok:
        FAILS.append(msg)


def state(page):
    return page.evaluate("""() => ({
      hash: location.hash, y: Math.round(scrollY),
      page: document.querySelector('.page:not([hidden])').dataset.page,
      open: [...document.querySelectorAll('dialog[open]')].map(d => d.id),
      menu: !document.getElementById('mmenu').hidden })""")


def back(page):
    page.go_back(wait_until="commit")
    page.wait_for_timeout(250)


with sync_playwright() as p:
    exe = os.environ.get("PW_CHROMIUM")
    browser = p.chromium.launch(**({"executable_path": exe} if exe else {}))
    for width, label in [(390, "phone"), (1440, "desktop")]:
        ctx = browser.new_context(viewport={"width": width, "height": 800}, has_touch=width < 900)
        ctx.route("https://embed.figma.com/**", lambda r: r.fulfill(status=200, content_type="text/html", body="<title>Figma embed</title><p>proto</p>"))
        ctx.route("https://fonts.googleapis.com/**", lambda r: r.fulfill(status=200, body=""))
        page = ctx.new_page()
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.goto(URL)
        page.wait_for_function("!document.documentElement.classList.contains('cms-loading')")
        print(f"--- {label} ({width}px)")

        # go to Work the way a visitor does, then scroll down to the projects
        page.click("footer [data-route='work']")
        page.wait_for_timeout(200)
        card = page.locator(".page:not([hidden]) #more-grid [data-case]").first
        card.scroll_into_view_if_needed()
        page.wait_for_timeout(200)

        # case pop-up: back closes it, same page, same spot
        card.click()
        page.wait_for_timeout(200)
        y0 = state(page)["y"]
        check(state(page)["open"] == ["caseDlg"], f"{label}: case pop-up opens")
        back(page)
        s = state(page)
        check(s["open"] == [] and s["page"] == "work" and s["hash"] == "#work", f"{label}: back closes the case pop-up and stays on Work ({s})")
        check(abs(s["y"] - y0) <= 2, f"{label}: back keeps the scroll spot ({y0} → {s['y']})")

        # case pop-up closed with ✕: history stays in sync, next back goes to Home
        card.click()
        page.wait_for_timeout(200)
        y0 = state(page)["y"]
        page.click("#caseDlg .dx")
        page.wait_for_timeout(250)
        s = state(page)
        check(s["open"] == [] and s["hash"] == "#work" and abs(s["y"] - y0) <= 2, f"{label}: ✕ closes the case pop-up in place ({s})")
        back(page)
        s = state(page)
        check(s["page"] == "home", f"{label}: after ✕, back goes to the previous page ({s})")
        page.go_forward(wait_until="commit")
        page.wait_for_timeout(250)
        check(state(page)["page"] == "work", f"{label}: forward returns to Work")

        # Escape closes in sync too
        card.scroll_into_view_if_needed()
        card.click()
        page.wait_for_timeout(200)
        page.keyboard.press("Escape")
        page.wait_for_timeout(250)
        check(state(page)["open"] == [] and state(page)["hash"] == "#work", f"{label}: Escape closes the case pop-up")

        # screens gallery, then the prototype from inside it
        sb = page.locator(".page:not([hidden]) [data-screens]").first
        sb.scroll_into_view_if_needed()
        sb.click()
        page.wait_for_timeout(250)
        y1 = state(page)["y"]
        s = state(page)
        check(s["open"] == ["shotsDlg"] and s["hash"].startswith("#screens/"), f"{label}: screens pop-up opens with its link ({s['hash']})")
        page.click("#shotsFigma [data-proto]")
        page.wait_for_timeout(400)
        check(sorted(state(page)["open"]) == ["protoDlg", "shotsDlg"], f"{label}: prototype opens over the screens")
        back(page)
        s = state(page)
        check(s["open"] == ["shotsDlg"] and s["hash"].startswith("#screens/"), f"{label}: back closes only the prototype ({s})")
        back(page)
        s = state(page)
        check(s["open"] == [] and s["hash"] == "#work" and s["page"] == "work" and abs(s["y"] - y1) <= 2, f"{label}: back closes the screens at the same spot ({s}, was y {y1})")

        # screens closed with ✕ restores the hash; prototype ✕ then back
        sb.click()
        page.wait_for_timeout(250)
        page.click("#shotsDlg .dx")
        page.wait_for_timeout(250)
        s = state(page)
        check(s["open"] == [] and s["hash"] == "#work", f"{label}: ✕ closes the screens and restores the link ({s})")
        pb = page.locator(".page:not([hidden]) [data-proto]").first
        pb.scroll_into_view_if_needed()
        pb.click()
        page.wait_for_timeout(400)
        check(state(page)["open"] == ["protoDlg"], f"{label}: prototype pop-up opens from a card")
        frame_src = page.get_attribute("#protoFrame", "src") or ""
        check("embed.figma.com" in frame_src, f"{label}: prototype frame loads the Figma embed")
        back(page)
        s = state(page)
        check(s["open"] == [] and s["page"] == "work", f"{label}: back closes the prototype ({s})")
        check(not page.get_attribute("#protoFrame", "src"), f"{label}: prototype frame is cleared on close")
        pb.click()
        page.wait_for_timeout(400)
        page.click("#protoDlg .dx")
        page.wait_for_timeout(250)
        back(page)
        check(state(page)["page"] == "home", f"{label}: after prototype ✕, back goes to the previous page")

        # a page link inside a pop-up replaces the pop-up's entry
        page.go_forward(wait_until="commit")
        page.wait_for_timeout(250)

        if width < 900:
            page.evaluate("scrollTo(0, 600)")
            page.wait_for_timeout(100)
            page.click("#burger")
            page.wait_for_timeout(150)
            check(state(page)["menu"], f"{label}: menu opens")
            back(page)
            s = state(page)
            check(not s["menu"] and s["page"] == "work", f"{label}: back closes the menu and stays on the page ({s})")
            page.click("#burger")
            page.wait_for_timeout(150)
            page.click("#mmenu [data-route='studio']")
            page.wait_for_timeout(250)
            back(page)
            s = state(page)
            check(not s["menu"] and s["page"] == "work", f"{label}: after a menu link, back returns to the page before ({s})")

        check(not errors, f"{label}: no JS errors {errors}")
        ctx.close()
    browser.close()

print(f"\n{len(FAILS)} failed" if FAILS else "\nAll passed")
sys.exit(1 if FAILS else 0)
