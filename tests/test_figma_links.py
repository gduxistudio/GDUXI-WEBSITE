#!/usr/bin/env python3
"""Click every case-study card: Figma cards must open their file in a new tab,
and cards without a Figma link must open the pop-up with only that project's images.

Usage: python3 tests/test_figma_links.py http://localhost:8000/index.html
Figma itself is stubbed, so this checks the links, not the Figma sharing settings.
"""
import json
import os
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000/index.html"
PROJECTS = json.loads((Path(__file__).resolve().parent.parent / "content" / "projects.json").read_text("utf-8"))["projects"]
FAILS = []

with sync_playwright() as p:
    exe = os.environ.get("PW_CHROMIUM")
    browser = p.chromium.launch(**({"executable_path": exe} if exe else {}))
    for width, label in [(1440, "desktop"), (390, "phone")]:
        ctx = browser.new_context(viewport={"width": width, "height": 900})
        ctx.route("https://www.figma.com/**", lambda r: r.fulfill(status=200, content_type="text/html", body="<title>Figma</title>"))
        ctx.route("https://fonts.googleapis.com/**", lambda r: r.fulfill(status=200, body=""))
        page = ctx.new_page()
        page.goto(URL)
        page.wait_for_function("!document.documentElement.classList.contains('cms-loading')")
        targets = [("home", ".page:not([hidden]) [data-projects='all'] .proj")]
        targets.append(("work", ".page:not([hidden]) .joint"))
        targets.append(("work", ".page:not([hidden]) #more-grid .proj"))
        for route, sel in targets:
            page.evaluate(f"location.hash='#{route}'")
            page.wait_for_timeout(300)
            cards = page.locator(sel)
            for i in range(cards.count()):
                card = cards.nth(i)
                title = card.locator(".h3,.h2").first.inner_text()
                proj = next((x for x in PROJECTS if x["title"] == title), {})
                want = proj.get("figma")
                card.scroll_into_view_if_needed()
                if not want:
                    card.click()
                    page.wait_for_selector("#caseDlg[open]")
                    srcs = page.evaluate("[...document.querySelectorAll('#casePages img')].map(i=>i.getAttribute('src'))")
                    loaded = page.evaluate("Promise.all([...document.querySelectorAll('#casePages img')].map(i=>i.decode().then(()=>i.naturalWidth>0,()=>false)))")
                    exp = [x.lstrip("/") for x in proj.get("pages", [])]
                    ok = page.inner_text("#case-h") == title and srcs == exp and all(loaded) and len(ctx.pages) == 1
                    print(("  ok   " if ok else "  FAIL ") + f"{label} {route}: {title} -> pop-up with {len(srcs)} case-study image(s)")
                    if not ok:
                        FAILS.append(f"{label} {title}")
                    page.click("#caseDlg [data-close]")
                    continue
                with ctx.expect_page() as info:
                    card.click()
                tab = info.value
                tab.wait_for_load_state()
                ok = want and tab.url == want
                print(("  ok   " if ok else "  FAIL ") + f"{label} {route}: {title} -> {tab.url[:70]}")
                if not ok:
                    FAILS.append(f"{label} {title}")
                tab.close()
        ctx.close()
    browser.close()

print(f"\n{'ALL PASSED' if not FAILS else str(len(FAILS)) + ' FAILED'}")
sys.exit(1 if FAILS else 0)
