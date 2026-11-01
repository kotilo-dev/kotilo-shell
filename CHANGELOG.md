# Changelog

All notable changes are recorded here. Format: Keep a Changelog; versioning: SemVer.

## [Unreleased]

### Added
- Trade tab: up to four panels you define in Settings, for stocks, funds, currencies and metals from Yahoo Finance and TEFAS, with labels and simple formulas such as gram gold
- GitHub tab with separate panels for notifications, your pull requests, review requests and the repositories on this machine with their commit status, each with a More link to its GitHub page
- Dashboard grid with a profile card with your own picture, weather, a clock with up to two world clocks, calendar and media with a cava spectrum (API 1.13). Weather uses Open-Meteo and stays offline until you set a city
- Panel with tabs, opened from the date and time: Overview, System, Agents, GitHub and RSS. System is a task manager for CPU, memory, disk, network and GPU, with processes grouped by name (`dashboard.tab`, API 1.12, ADR-0017)
- Windows list in the bar: pick a window to switch to its workspace and focus it (`Workspaces.workspaceOf`, API 1.11)
- Bar scale setting: small, normal and large (API 1.10)
- Kotilo shell icon at the left of the bar, which opens settings
- Workspace indicator styles: numbers, Roman numerals, dots and circles
- Dashboard with a `dashboard.card` slot (API 1.7, ADR-0015)
- Settings panel with general settings and forms generated from each plugin's schema (API 1.6, ADR-0004)

### Changed
- Panels fade and rise in and leave quickly, with one hover and press treatment, soft shadows with Qt 6.9 or newer, tonal cards and switches in settings (API 1.9, ADR-0016)
- Bar: neutral colours at rest, UI font with mono for git, 16 px icons, 36 px height, and related modules grouped (`barGroup`, API 1.8)

### Fixed
- A hidden bar plugin no longer leaves an extra gap
- The center of the bar sits on the true center, and only moves aside to avoid the left and right groups
- The sparkline reads at low load, and the control center pill has a sliders icon and a tooltip
- Extra time zones in `bar.clock` show the zone's time; they always showed local time before
- Tooltips open above a bottom bar instead of off the screen

### Security
- `bar.git` no longer runs a program named by `core.fsmonitor` in the config of a repository it polls
- Nothing is saved while `settings.json` has a syntax error, so a hand edit in progress cannot be overwritten

## [0.3.0] - 2026-11-01

### Added
- CPU sparkline and network down/up in `bar.resources`, each with a setting; `Pill` takes child items
- `scripts/check-modules.sh` names a missing Quickshell module at install and on `kotilo-shell start`
- Every notification action can be reached from the keyboard
- Bar keyboard mode: `qs -c kotilo ipc call bar toggle`, with `Shell.barKey` for custom items (API 1.5, ADR-0014)
- Agents list in the control center
- Claude Code hook adapter: `kotilo-agent hook claude` shows sessions in the bar and answers permission prompts from it (ADR-0013)
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
- Memory budget is now 150 MB PSS, since an empty Quickshell is already over 150 MB RSS
- Agent protocol: optional `agent` on approvals and `once` on status, and a request is withdrawn when its agent reports another state (ADR-0003)
- `kotilo-agent` is installed on `PATH`
- Idle CPU cut from about 3 % to 0.9 % of one core: ports read from `/proc`, containers polled every 2 minutes, git every 10 s

### Security
- `plugin install` and `plugin remove` reject ids that are not valid, which could otherwise delete paths outside the plugin folder
