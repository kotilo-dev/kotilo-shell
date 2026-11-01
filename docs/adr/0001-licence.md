# ADR-0001 — Licence

- Status: proposed
- Date: 2026-10-31

## Context
Kotilo Shell will be open source and may accept sponsorship. Comparable shells: Noctalia and Caelestia use GPL-3.0; DankMaterialShell uses MIT. Quickshell itself is LGPL-3.0. We want maximum contributions back and protection against closed forks, while staying compatible with the rest of the Kotilo family (Kotilo Desktop and Launcher licences TBD, ideally identical).

## Options
1. **GPL-3.0-or-later** — copyleft; forks must stay open; plugins written in QML and loaded at runtime are generally considered separate works, but document this explicitly for plugin authors.
2. **MIT** — permissive; simplest for adoption and for corporate contributors; allows closed forks.
3. **MPL-2.0** — file-level copyleft; middle ground.

## Decision
_Pending._ Leaning GPL-3.0-or-later for the shell, with an explicit note that third-party plugins and themes are not derivative works and may use any licence.

## Consequences
- Positive: contributions flow back; aligns with Noctalia/Caelestia community norms.
- Negative: some companies avoid GPL; dual-licensing requests possible.
- Follow-ups: replace `LICENSE.md`, add SPDX headers, same decision for Kotilo Desktop/Launcher.
