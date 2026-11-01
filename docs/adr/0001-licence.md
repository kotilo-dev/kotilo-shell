# ADR-0001 — Licence

- Status: accepted
- Date: 2026-10-31

## Context
Kotilo Shell will be open source and may accept sponsorship. Comparable shells: Noctalia and Caelestia use GPL-3.0; DankMaterialShell uses MIT. Quickshell itself is LGPL-3.0. We want maximum contributions back and protection against closed forks, while staying compatible with the rest of the Kotilo family (Kotilo Desktop and Launcher licences TBD, ideally identical).

## Options
1. **GPL-3.0-or-later** — copyleft; forks must stay open; plugins written in QML and loaded at runtime are generally considered separate works, but document this explicitly for plugin authors.
2. **MIT** — permissive; simplest for adoption and for corporate contributors; allows closed forks.
3. **MPL-2.0** — file-level copyleft; middle ground.

## Decision
GPL-3.0-or-later for the shell. Third-party plugins and themes that are loaded at runtime are treated as separate works, not derivatives of the shell, and may use any licence (stated in `README.md` and `docs/PLUGINS.md`).

## Consequences
- Positive: contributions flow back; aligns with Noctalia/Caelestia community norms.
- Negative: some companies avoid GPL; dual-licensing requests possible.
- Follow-ups: same decision for Kotilo Desktop/Launcher.
