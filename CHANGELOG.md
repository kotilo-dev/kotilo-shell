# Changelog

All notable changes are recorded here. Format: Keep a Changelog; versioning: SemVer.

## [Unreleased]

### Added
- Plugin API 1.4: popups, palette actions, tooltips, notification handlers, script actions and timeouts (ADR-0012)
- Theme targets for ghostty and kitty: generated colour files you include from your own config (ADR-0011)
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

### Changed
- Idle CPU cut from about 3 % to 0.9 % of one core: ports read from `/proc`, containers polled every 2 minutes, git every 10 s

### Security
- `plugin install` and `plugin remove` reject ids that are not valid, which could otherwise delete paths outside the plugin folder
