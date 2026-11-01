# ADR-0011 — Theme targets write only the shell's own files

- Status: accepted
- Date: 2026-11-01

## Context
Themes should reach other apps, but their config files belong to the user, and on Omarchy they already include Omarchy's theme. Editing them risks breaking them and fights other tools. `docs/THEMES.md` originally planned to write into each app's config folder.

## Decision
A `theme.target` is a `kind: "provider"` plugin whose root is `C.ThemeTarget`, with a `template.conf` beside it. On every theme change it renders to `$XDG_DATA_HOME/kotilo/shell/generated/<file>`, and writes nothing else. The user opts in by adding one include line to the app's config, after any line that also sets a theme. Sending a running app the reload signal is a separate per-target setting, `reload`, off by default. `theme.propagate: false` stops all of it. Templates use the minimal mustache syntax in `Shell/internal/template.js`. A missing token aborts the render, so a bad template leaves the last good file in place.

## Consequences
- Positive: uninstalling leaves no trace in app configs, and a failed render cannot damage anything.
- Negative / risks: one manual line per app. Without `reload`, running apps change only when they next read their config.
- Follow-ups: more targets from SPEC §4.3.
