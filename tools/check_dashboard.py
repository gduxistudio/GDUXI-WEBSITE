#!/usr/bin/env python3
"""Check that admin/config.yml describes content/*.json exactly.

Decap silently drops any JSON key the config does not list the next time
someone saves, so every key must exist on both sides.
Usage: python3 tools/check_dashboard.py   (needs: pip install pyyaml)
"""
import json
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent


def compare(fields, data, where, problems):
    names = {f["name"]: f for f in fields}
    if not isinstance(data, dict):
        problems.append(f"{where}: expected an object in JSON")
        return
    for key in data:
        if key not in names:
            problems.append(f"{where}.{key}: in JSON but missing from config.yml")
    for name, f in names.items():
        if name not in data:
            if f.get("required", True):
                problems.append(f"{where}.{name}: in config.yml but missing from JSON")
            continue
        value, widget = data[name], f.get("widget", "string")
        if widget == "list":
            if not isinstance(value, list):
                problems.append(f"{where}.{name}: config says list, JSON has {type(value).__name__}")
            elif "fields" in f:
                for i, item in enumerate(value):
                    compare(f["fields"], item, f"{where}.{name}[{i}]", problems)
            elif any(not isinstance(v, str) for v in value):
                problems.append(f"{where}.{name}: single-field list should hold strings")
        elif widget == "object":
            compare(f["fields"], value, f"{where}.{name}", problems)
        elif widget == "select":
            allowed = [o["value"] if isinstance(o, dict) else o for o in f["options"]]
            if value not in allowed:
                problems.append(f"{where}.{name}: '{value}' is not one of {allowed}")
        elif not isinstance(value, str):
            problems.append(f"{where}.{name}: expected text, JSON has {type(value).__name__}")


def main() -> int:
    cfg = yaml.safe_load((ROOT / "admin" / "config.yml").read_text("utf-8"))
    problems, seen = [], set()
    for coll in cfg["collections"]:
        for entry in coll["files"]:
            path = ROOT / entry["file"]
            seen.add(path.name)
            if not path.exists():
                problems.append(f"{entry['file']}: file does not exist")
                continue
            compare(entry["fields"], json.loads(path.read_text("utf-8")), path.stem, problems)
    for p in (ROOT / "content").glob("*.json"):
        if p.name not in seen:
            problems.append(f"content/{p.name}: not in the dashboard")
    if problems:
        print("Dashboard and content do not match:")
        for p in problems:
            print("  -", p)
        return 1
    print(f"OK: admin/config.yml matches all {len(seen)} content files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
