#!/usr/bin/env python3
"""Convert a Base16/Base24 scheme YAML (tinted-theming format) into a Kotilo tokens.json.
Usage: scripts/base16-to-tokens.py scheme.yaml [--id my-theme] > themes/my-theme/tokens.json
Mapping per docs/THEMES.md §3. Minimal YAML parsing on purpose (schemes are flat key: value files)."""
import json, re, sys
from pathlib import Path

SCALAR = re.compile(r"""^\s*([A-Za-z0-9_-]+):\s*(?:"([^"]*)"|'([^']*)'|([^#]*?))\s*(?:\#.*)?$""")

def parse_yaml(text):
    """Flat key: value reader. Comments only count outside quotes: colours are written "#1A1B26"."""
    out = {}
    for line in text.splitlines():
        m = SCALAR.match(line)
        if m: out[m.group(1)] = next(g for g in m.groups()[1:] if g is not None).strip()
    return out

def norm(c):
    c = "#" + c.strip().lstrip("#").lower()
    if not re.fullmatch(r"#[0-9a-f]{6}", c): sys.exit(f"bad colour: {c}")
    return c

def shift(hexc, amount):
    """Darken (negative) or lighten (positive) by a fixed step."""
    r, g, b = (int(hexc[i:i+2], 16) for i in (1, 3, 5))
    cl = lambda v: max(0, min(255, v + amount))
    return "#%02x%02x%02x" % (cl(r), cl(g), cl(b))

def main():
    args = sys.argv[1:]
    if not args: print(__doc__); sys.exit(1)
    src = Path(args[0]); scheme = parse_yaml(src.read_text(encoding="utf-8"))
    theme_id = args[args.index("--id") + 1] if "--id" in args else re.sub(r"[^a-z0-9-]+", "-", src.stem.lower()).strip("-")
    # Current schemes nest colours under palette:, older ones do not. The flat parse reads both.
    b = {k: norm(v) for k, v in scheme.items() if re.fullmatch(r"base[0-9A-F]{2}", k)}
    need = [f"base0{i}" for i in "0123456789ABCDEF"]
    missing = [k for k in need if k not in b]
    if missing: sys.exit(f"scheme missing keys: {missing}")
    declared = scheme.get("variant")
    is_dark = declared == "dark" if declared in ("dark", "light") else sum(int(b["base00"][i:i+2], 16) for i in (1, 3, 5)) < 384
    step = -8   # mantle and crust are darker than base in light themes too
    # Base24's bright colours, or their Base16 equivalents.
    bright = {"base12": "base08", "base13": "base0A", "base14": "base0B", "base15": "base0C", "base16": "base0D", "base17": "base0E"}
    bright = {k: b.get(k, b[fallback]) for k, fallback in bright.items()}
    tokens = {
        "id": theme_id,
        "name": scheme.get("name") or scheme.get("scheme") or theme_id,
        "variant": "dark" if is_dark else "light",
        "source": "base24" if "base10" in b or scheme.get("system") == "base24" else "base16",
        "upstream": scheme.get("author", ""),
        "bg": {"base": b["base00"], "mantle": shift(b["base00"], step), "crust": shift(b["base00"], 2 * step)},
        "surface": [b["base01"], b["base02"], b["base03"]],
        "text": {"primary": b["base05"], "secondary": b["base04"], "muted": b["base03"], "onAccent": b["base00"]},
        "accent": {"primary": b["base0D"], "secondary": b["base0E"]},
        "state": {"success": b["base0B"], "warning": b["base09"], "error": b["base08"], "info": b["base0C"]},
        "palette": {"red": b["base08"], "orange": b["base09"], "yellow": b["base0A"], "green": b["base0B"], "teal": b["base0C"], "blue": b["base0D"], "purple": b["base0E"], "pink": b["base0F"]},
        "radius": {"sm": 6, "md": 10, "lg": 14},
        "space": {"xs": 4, "sm": 8, "md": 12, "lg": 16, "xl": 24},
        "font": {"ui": "Inter", "mono": "JetBrains Mono", "display": "Inter", "size": 13},
        "shadow": {"panel": "0 24px 64px rgba(0,0,0,0.6)"},
        "ansi": [b["base00"], b["base08"], b["base0B"], b["base0A"], b["base0D"], b["base0E"], b["base0C"], b["base05"],
                 b["base03"], bright["base12"], bright["base14"], bright["base13"], bright["base16"], bright["base17"], bright["base15"], b["base07"]],
        "wallpaper": None,
    }
    json.dump(tokens, sys.stdout, indent=2); print()

if __name__ == "__main__":
    main()
