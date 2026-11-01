# Changelog

All notable changes are recorded here. Format: Keep a Changelog; versioning: SemVer.

## [Unreleased]

### Added
- Focus Mode: Pomodoro cycle, popups held back except critical ones and approvals, compact bar, optional mute
- Agent protocol over a Unix socket, with a bar module, approval popups, an agents panel and `scripts/kotilo-agent` (ADR-0003)
- Git, Containers and Ports bar modules (ADR-0010)
- Control center with quick tiles, volume and brightness sliders, per-app audio, theme swatches and a media card (ADR-0009)
- Notification daemon with popups, a history panel grouped by app, per-app rules and do not disturb (ADR-0002)
- Command palette with Apps, Windows, Projects, Themes and Clipboard providers, and a palette provider API (API 1.1, ADR-0008)
- Licence: GPL-3.0-or-later, with SPDX headers on all source files
- Repository skeleton, specification, plugin and theme documentation
- Core QML skeleton: ShellRoot, Bar, PluginHost, Theme, Settings
- Compositor adapter interface with Niri and Hyprland stubs
- Themes: catppuccin-mocha, gruvbox-dark
- Example plugins: bar.workspaces, bar.clock, script-plugin example
- Install scripts (pacman/dnf/apt), dev/test/package scripts, AUR/COPR/Nix stubs, CI
