# Kotilo Shell — Theme Guide

## 1. Model

```
scheme (16/24 raw colours)  →  tokens (semantic)  →  shell UI + app templates
```

- **Scheme sources:** Base16/Base24 YAML (tinted-theming), first-class `tokens.json`, matugen output (Kotilo Dynamic), Omarchy theme folder (import).
- **Tokens** are what every plugin uses. Never reference raw scheme colours in QML.
- **Templates** render tokens into config files for external apps on every theme change.

## 2. tokens.json

```json
{
  "id": "catppuccin-mocha",
  "name": "Catppuccin Mocha",
  "variant": "dark",
  "source": "first-class",
  "bg":      { "base": "#1e1e2e", "mantle": "#181825", "crust": "#11111b" },
  "surface": ["#313244", "#45475a", "#585b70"],
  "text":    { "primary": "#cdd6f4", "secondary": "#a6adc8", "muted": "#6c7086", "onAccent": "#11111b" },
  "accent":  { "primary": "#89b4fa", "secondary": "#cba6f7" },
  "state":   { "success": "#a6e3a1", "warning": "#fab387", "error": "#f38ba8", "info": "#94e2d5" },
  "palette": { "red": "#f38ba8", "orange": "#fab387", "yellow": "#f9e2af", "green": "#a6e3a1",
               "teal": "#94e2d5", "blue": "#89b4fa", "purple": "#cba6f7", "pink": "#f5c2e7" },
  "radius":  { "sm": 6, "md": 10, "lg": 14 },
  "space":   { "xs": 4, "sm": 8, "md": 12, "lg": 16, "xl": 24 },
  "font":    { "ui": "Inter", "mono": "JetBrains Mono", "display": "Inter", "size": 13 },
  "shadow":  { "panel": "0 24px 64px rgba(0,0,0,0.6)" },
  "ansi":    ["#45475a", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#bac2de",
              "#585b70", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#a6adc8"],
  "wallpaper": null
}
```

Schema: `themes/schema/tokens.schema.json`. Contrast rule enforced by `scripts/check-contrast.sh`: `text.primary` ≥ 4.5:1 on `bg.base`, `bg.mantle`, `surface[0]`; `text.secondary` ≥ 4.5:1 on `bg.base`; `text.onAccent` ≥ 4.5:1 on `accent.primary`.

## 3. Base16 → tokens mapping

| Token | Base16 |
|---|---|
| bg.crust / mantle / base | base00 (darkened 2 steps) / base00 (darkened 1) / base00 |
| surface[0..2] | base01 / base02 / base03 |
| text.muted / secondary / primary | base03 / base04 / base05 |
| accent.primary / secondary | base0D / base0E |
| state.success / warning / error / info | base0B / base09 / base08 / base0C |
| ansi | base00,08,0B,0A,0D,0E,0C,05, base03,08,0B,0A,0D,0E,0C,07 |

`scripts/base16-to-tokens.py scheme.yaml > themes/<id>/tokens.json`. Base24 adds the bright ANSI set directly.

## 4. Bundled first-class themes (hand-tuned tokens)

Catppuccin ×4 · Gruvbox (dark/light, hard/medium/soft, Material) · Tokyo Night ×4 · Rosé Pine ×3 · Nord · Dracula · Everforest ×4 · Kanagawa ×3 · One Dark · Solarized ×2 · Monokai Pro · Ayu ×3 · Nightfox family · GitHub ×3 · Vesper · Oxocarbon · Cyberdream · Flexoki · Poimandres · Modus ×2 · Night Owl · Palenight · Kotilo Dynamic.

Shipped in 0.1: catppuccin-mocha, gruvbox-dark, tokyo-night, rose-pine, nord, everforest-dark. Each remaining theme is a `tokens.json` PR — upstream palettes are the source of truth; link the upstream repo in `source`.

## 5. Kotilo Dynamic (Material You)

`matugen image <wallpaper> --json hex` → mapped to tokens (`primary`→accent.primary, `tertiary`→accent.secondary, `surface*`→bg/surface, `on_surface`→text). Both light and dark variants are produced; `settings.theme.autoVariant` chooses by time or sunrise.

## 6. Propagation targets

Each target is a `theme.target` provider plugin (`plugins/core/theme.<app>/`). A target renders one or more files and triggers a reload.

| Target | Output | Reload |
|---|---|---|
| ghostty | `~/.config/ghostty/themes/kotilo` | SIGUSR2 / config reload |
| kitty | `~/.config/kitty/kotilo.conf` | `kitty @ set-colors` |
| alacritty / foot | theme file | live-reload on write |
| neovim | `~/.config/nvim/colors/kotilo.lua` | `nvim --server … --remote-send` |
| vscode | `settings.json` `workbench.colorTheme` | automatic |
| gtk3/4 | `gtk.css` + `gsettings color-scheme` | automatic |
| qt6ct | `colors/kotilo.conf` | new windows |
| btop, fzf, bat, starship, cava, yazi, lazygit | theme files | next launch |
| vencord, firefox userChrome | css | reload |
| wallpaper | `swww img` | immediate |

Templates use a minimal mustache syntax: `{{bg.base}}`, `{{accent.primary.rgb}}` (r,g,b), `{{ansi.3}}`, `{{#isDark}}…{{/isDark}}`.

## 7. Adding a theme

1. `themes/<id>/tokens.json` (copy an existing one).
2. `scripts/check-contrast.sh themes/<id>` must pass.
3. Screenshot in `docs/screenshots/themes/<id>.png`.
4. Add to the table in §4.
