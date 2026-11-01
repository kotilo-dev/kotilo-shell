# ADR-0005 — Separate user directories from Kotilo Desktop

- Status: accepted
- Date: 2026-11-01

## Context
Kotilo Desktop already runs on Linux and owns `~/.config/kotilo/{settings.json,state.json}`, `~/.local/share/kotilo/` (including its live `hub/hub.db`) and the `kotilo` command. Kotilo Shell was specified to use the same locations. Both apps have a `theme` settings key with no shared schema, `Settings.save()` would rewrite Desktop's file, and `uninstall.sh --purge` would delete Desktop's settings and database. `install.sh` would also write through `~/.local/bin/kotilo`, a symlink to Desktop's AppImage, and overwrite it.

## Decision
All Kotilo Shell user files live in a `shell/` subdirectory: `$XDG_CONFIG_HOME/kotilo/shell` (`settings.json`, `themes/`, `plugins/`), `$XDG_DATA_HOME/kotilo/shell` and `$XDG_CACHE_HOME/kotilo/shell`. The shell never reads, writes or deletes anything outside these directories in the `kotilo` namespace. `Shell.qml` is the only QML source of these paths. The CLI is `kotilo-shell`.

## Consequences
- Positive: either app can be installed, updated, purged or broken without affecting the other. `--purge` deletes only what the shell owns.
- Negative / risks: themes are not shared between the apps automatically, and paths are one level deeper than the original spec.
- Follow-ups: if the family wants shared theme tokens, define that as an explicit shared location and schema in a new ADR. Reading Desktop's settings is not the way to do it.
