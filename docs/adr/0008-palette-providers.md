# ADR-0008 — Palette providers and the shell.overlay slot

- Status: accepted
- Date: 2026-11-01

## Context
The palette must be a plugin like everything else, and each search source (apps, windows, themes, …) must be a provider third parties can also write. The 0.1 slots have nowhere to mount a plugin that owns a full-screen window, and `palette.provider` is only a name with no contract. Global keybinds differ per compositor, and the compositor must stay behind `services/wm/`.

## Decision
Add a `shell.overlay` slot for window-owning plugins. A provider is a `kind: "provider"` plugin in `palette.provider` that calls `Shell.registerPaletteProvider(item)` and exposes `title` and `items(query)`, returning rows; it calls `Shell.paletteDataChanged()` when they change. The palette ranks rows centrally with `Shell.fuzzyRank()`, title first and keywords second, so ranking is the same for every provider; a row may set its own `score` when fuzzy matching means nothing for its text, as with clipboard entries. The first row action is primary; `Tab` lists them all. The palette opens through IPC (`qs -c kotilo ipc call palette toggle`), and each user binds that in their compositor.

## Consequences
- Positive: one ranking, one keyboard model, and the API stays the one core providers use. Additive, so `apiVersion` becomes 1.1.0.
- Negative / risks: `items()` runs on the UI thread on each keystroke, so a provider must answer from memory and refresh its data elsewhere.
- Follow-ups: `settings.keybinds` is not applied by the shell. Write bindings into compositor config only if a later ADR decides to.
