# CLAUDE.md — Kotilo Shell

Kotilo Shell is a developer-focused Wayland desktop shell built on **Quickshell** (Qt 6 + QML).
It is part of the **Kotilo** family (kotilo.dev): Kotilo Desktop (AI-agent workspace, Windows/macOS),
Kotilo Launcher (Android) and Kotilo Shell (Linux). Shared design language, shared theme tokens,
shared agent-status protocol.

Read `docs/SPEC.md` before any non-trivial change. This file is about *how we work*; the spec is about *what we build*.

## Stack and ground rules

- Quickshell **0.3.2** (rev `2b4501a`, Arch `0.3.2.r7.g2b4501a`; pinned in `flake.nix` / `install/deps.sh`), Qt 6.8+, QML + plain JavaScript. No C++ unless a Quickshell primitive is missing — open an issue first.
- Compositor-agnostic. All compositor access goes through `services/wm/` (Niri and Hyprland adapters behind one interface). Never call `hyprctl` or the Niri socket from a module.
- Distro-agnostic. Nothing may assume Arch, Fedora or Nix paths. Use `XDG_*` variables and `Quickshell.env`.
- Theme-agnostic. Never hardcode a color, font or radius in a module. Use `Theme.*` tokens only.
- Every built-in module is implemented as a **plugin** through the same API third parties use (`docs/PLUGINS.md`). If the API cannot express what a core module needs, extend the API; do not bypass it.
- Config is data: `~/.config/kotilo/shell/settings.json` (+ `themes/`, `plugins/`). The rest of `~/.config/kotilo` and `~/.local/share/kotilo` belongs to Kotilo Desktop: never touch it (ADR-0005). Users must never need to edit QML.
- Performance budget: < 1 % CPU idle, < 150 MB PSS with the default module set, first paint of the bar < 300 ms. Lazy-load every popup/panel with `LazyLoader`.
- Accessibility: readable contrast in every bundled theme (text ≥ 4.5:1 on its surface), keyboard-navigable palette and control center, respect `prefers-reduced-motion` equivalent (`settings.animations = false`).

## Repository layout

```
shell.qml                 entry point (loads Shell/ and plugins)
Shell/                    core runtime: PluginHost, ThemeEngine, Settings, IPC
services/                 singletons: Audio, Network, Bluetooth, Battery, Brightness,
                          Notifications, Mpris, Clipboard, wm/{Niri,Hyprland,Interface}
components/               reusable UI: Pill, Card, Slider, Toggle, Icon, Surface, Text
plugins/core/<id>/        built-in plugins (bar.workspaces, bar.git, bar.agents, palette, ...)
themes/<id>/              bundled themes (tokens.json + app templates for export)
assets/                   icons (SVG), fonts list, logo
install/                  deps.sh (dnf/pacman/apt detect), install.sh, uninstall.sh
packaging/                aur/, copr/, nix/
docs/                     SPEC.md, PLUGINS.md, THEMES.md, CONTRIBUTING.md
tests/                    qmltestrunner tests + smoke scripts
```

## Working agreements for Claude Code

- Start every session by reading `docs/SPEC.md` § Current milestone and `TODO.md`. Work on one checklist item at a time; tick it when done.
- Before writing QML for a Quickshell type, read its docs page from the pinned Quickshell version (`docs/quickshell-api/` mirror or `qs --help`). Do not guess property names — Quickshell API changes between versions.
- Run after every change: `qs -c kotilo` (or `./scripts/dev.sh`, which restarts the shell and tails `~/.cache/kotilo/log`). A change is not done until the shell starts with zero QML warnings.
- Prefer editing existing files over creating new ones. New plugin → `plugins/core/<id>/{manifest.json,Main.qml}` only.
- Keep PRs/commits small and single-purpose. Commit message style: `area: imperative summary` (e.g. `bar.git: show ahead/behind counts`).
- Never commit `settings.json`, logs, or anything under `~/.config`.
- When a decision is architectural (new service, new slot type, API change) write a 10-line ADR in `docs/adr/NNNN-title.md` before implementing.
- If a step needs a tool that is not installed, add it to `install/deps.sh` with a per-distro package name, never install ad hoc without recording it.
- Reference implementations for patterns (do not copy code, GPL/MIT licences differ): DankMaterialShell, Noctalia, Caelestia, end-4 dots, Omarchy. They live under `ref/` (git-ignored); read them when stuck on a Quickshell idiom.

## Definitions of done

- **Module/plugin:** manifest valid, renders in all bundled themes, keyboard reachable, no hardcoded colors, settings schema present, screenshot in `docs/screenshots/`.
- **Service:** singleton, exposes `ready` + error state, degrades gracefully when the backend is missing (e.g. no Bluetooth adapter).
- **Theme:** `tokens.json` complete, contrast check passes (`scripts/check-contrast.sh`), exported templates render in ghostty/kitty/nvim.
- **Release:** `CHANGELOG.md` updated, version bumped in `manifest.json` and packaging, `install.sh` tested in Arch, Fedora and Ubuntu distrobox containers.

## Commands

```
./scripts/dev.sh            run shell with live reload + log tail
./scripts/test.sh           qmltestrunner + manifest validation
./scripts/check-contrast.sh validate all themes
./scripts/package.sh        build tarball + update AUR/COPR/Nix metadata
```
