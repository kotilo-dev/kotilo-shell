#!/usr/bin/env python3
"""Regression test for scripts/base16-to-tokens.py against tests/fixtures/base16-sample.yaml."""
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
out = subprocess.run([sys.executable, "-I", str(ROOT / "scripts/base16-to-tokens.py"), str(ROOT / "tests/fixtures/base16-sample.yaml")],
                     capture_output=True, text=True, check=True).stdout
t = json.loads(out)
checks = {
    "colour with inline comment": t["bg"]["base"] == "#fafafa",
    "hash in a quoted name": t["name"] == "Sample #1",
    "single-quoted value": t["upstream"] == "Kotilo tests",
    "declared variant": t["variant"] == "light",
    "mantle darker in a light theme": t["bg"]["mantle"] == "#f2f2f2",
    "bright red falls back to base08": t["ansi"][9] == "#aa0000",
    "bright cyan falls back to base0C": t["ansi"][14] == "#00aaaa",
    "id from file name": t["id"] == "base16-sample",
}
failed = [name for name, ok in checks.items() if not ok]
for name in failed: print("  FAIL", name)
print(f"  {len(checks) - len(failed)}/{len(checks)} converter checks pass")
sys.exit(1 if failed else 0)
