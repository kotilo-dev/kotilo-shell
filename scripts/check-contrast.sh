#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Validates every themes/*/tokens.json against the schema subset and WCAG contrast rules (docs/THEMES.md §2).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-$ROOT/themes}"
python3 -I - "$TARGET" <<'PY'
import json, sys
from pathlib import Path

def lum(hexc):
    r, g, b = (int(hexc[i:i+2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)

def ratio(a, b):
    la, lb = lum(a), lum(b); hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

RULES = [  # (fg path, bg path, minimum)
    (("text", "primary"),   ("bg", "base"),   4.5),
    (("text", "primary"),   ("bg", "mantle"), 4.5),
    (("text", "primary"),   ("surface", 0),   4.5),
    (("text", "secondary"), ("bg", "base"),   4.5),
    (("text", "muted"),     ("bg", "base"),   3.0),
    (("text", "onAccent"),  ("accent", "primary"), 4.5),
    (("accent", "primary"), ("bg", "base"),   3.0),
    (("state", "error"),    ("bg", "base"),   3.0),
    (("state", "warning"),  ("bg", "base"),   3.0),
]
REQUIRED = ["id", "name", "variant", "bg", "surface", "text", "accent", "state", "radius", "space", "font", "ansi"]

def get(t, path):
    v = t
    for p in path: v = v[p]
    return v

target = Path(sys.argv[1])
files = [target / "tokens.json"] if (target / "tokens.json").exists() else sorted(target.glob("*/tokens.json"))
bad = 0
for f in files:
    t = json.loads(f.read_text()); errs = []
    for k in REQUIRED:
        if k not in t: errs.append(f"missing {k}")
    if "ansi" in t and len(t["ansi"]) != 16: errs.append("ansi must have 16 colours")
    if not errs:
        for fg, bg, mn in RULES:
            r = ratio(get(t, fg), get(t, bg))
            if r < mn: errs.append(f"{'.'.join(map(str, fg))} on {'.'.join(map(str, bg))} = {r:.2f} < {mn}")
    if errs: bad += 1; print(f"  FAIL {f.parent.name}"); [print("    -", e) for e in errs]
    else: print(f"  ok   {f.parent.name}")
print(f"{len(files) - bad}/{len(files)} themes pass")
sys.exit(1 if bad else 0)
PY
