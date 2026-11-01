# ADR-0004 — Settings GUI inside the shell

- Status: accepted
- Date: 2026-11-01

## Context
Users must never need to edit QML, and every plugin already ships `settings.schema.json`. 0.4 needs a GUI for those settings. It has to work for third-party plugins with no extra code, use the theme, and stay out of the memory budget when closed.

## Options
1. **A panel inside the shell**: shares theme tokens, `Settings` and the plugin list.
2. **A separate app**: nothing in the shell's memory, but a second process, duplicated theming and a second writer of `settings.json`.

## Decision
Option 1: the `settings` plugin, a lazy panel opened by `qs -c kotilo ipc call settings toggle` or the palette. A General group covers the shell's own settings. Plugin forms are generated from each schema by `Shell.form*`, so a plugin gets a form by shipping a schema. Booleans, numbers, strings and enums are editable; arrays and objects show as read-only rows that point to `settings.json`. Changes save at once. Saving is refused while `settings.json` does not parse, because the memory copy would overwrite the user's hand edits.

## Consequences
- Positive: third-party plugins get a settings form for free. Additive, so `apiVersion` becomes 1.6.0.
- Negative / risks: the panel adds memory while open, and panels keep part of it after closing (see `TODO.md`). There is no undo, since each change applies at once.
- Follow-ups: editors for arrays and objects.
