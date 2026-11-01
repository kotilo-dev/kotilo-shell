# ADR-0012 — Plugin API v1 surface

- Status: accepted
- Date: 2026-11-01

## Context
`docs/PLUGINS.md` promised more than the code did: popups, palette actions, tooltips, script actions and a `notification.handler` slot, and it described base types that never existed. Plugin authors build on the document, so it has to be true before the API can settle.

## Decision
Implement the promises that are small and needed: `Shell.openPopup` hosted by `Shell/PopupHost.qml`, `Shell.registerPaletteAction` shown by a `palette.actions` provider, tooltips on `Pill`, script `actions`, `percentage` and a timeout, `notification.handler`, and `qs ipc call plugins reload` for plugins outside the shell folder. `apiVersion` becomes 1.4.0. The documented contracts are the real ones: `Shell.register…` calls and `C.Tile`/`C.ThemeTarget` roots, not base types. `wm.adapter`, `dashboard.card` and `lock.widget` stay reserved: they validate but nothing mounts them yet. A popup file must be a plain name inside the plugin's own folder.

`plugin install` rejects ids that are not the manifest pattern, because the id becomes a path passed to `rm -rf`, and warns when code runs processes without declaring `process`. This is a warning only: QML has no sandbox.

## Consequences
- Positive: the document matches the code, and third parties get what core plugins use.
- Negative / risks: the API is still draft until the 1.0 freeze. Script `actions` appear in the palette rather than on the widget.
- Follow-ups: the reserved slots, a reviewed index for the Plugin Store (0.4).
