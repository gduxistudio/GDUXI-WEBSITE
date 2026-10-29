#!/usr/bin/env python3
"""Refresh index.html from content/*.json.

Updates two things so the page still reads correctly if the JSON fetch fails
(or JavaScript is off):
  1. the inline <script type="application/json" id="content-fallback"> backup
  2. the static text inside every simple [data-c="file.field"] element

Run after hand-editing any file in content/:  python3 tools/sync_content.py
"""
import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FILES = ["home", "work", "studio", "services", "contact", "founders", "projects"]


def main() -> int:
    data = {n: json.loads((ROOT / "content" / f"{n}.json").read_text("utf-8")) for n in FILES}
    page = (ROOT / "index.html").read_text("utf-8")

    blob = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    page, n = re.subn(
        r'(<script type="application/json" id="content-fallback">)(.*?)(</script>)',
        lambda m: m.group(1) + blob + m.group(3),
        page,
        flags=re.S,
    )
    if n != 1:
        print("content-fallback block not found", file=sys.stderr)
        return 1

    def value(path):
        node = data
        for part in path.split("."):
            if not isinstance(node, dict) or part not in node:
                return None
            node = node[part]
        return node if isinstance(node, str) else None

    changed = 0

    def fill(m):
        nonlocal changed
        v = value(m.group(3))
        if v is None or "<" in m.group(4):
            return m.group(0)
        new = html.escape(v, quote=False).replace("\n", "<br>")
        if new != m.group(4):
            changed += 1
        return m.group(1) + new + m.group(5)

    page = re.sub(r'(<(\w+)\b[^>]*\bdata-c="([^"]+)"[^>]*>)([^<]*(?:<br>[^<]*)*)(</\2>)', fill, page)
    (ROOT / "index.html").write_text(page, "utf-8")
    print(f"content-fallback refreshed ({len(blob)} chars), {changed} static text block(s) updated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
