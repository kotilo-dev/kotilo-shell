# TODO — working list for Claude Code

Mirror of `docs/SPEC.md` §10. Tick here, keep SPEC in sync at milestone end.

## 0.1 — Bar + themes + adapters

- [x] Repo skeleton, docs, scripts, packaging stubs
- [x] Verify Quickshell API of every `// TODO(api)` comment against the pinned version
- [x] `services/wm/Niri.qml`: parse `niri msg --json event-stream` (WorkspacesChanged, WorkspaceActivated, WindowFocusChanged)
- [x] `services/wm/Hyprland.qml`: map `Quickshell.Hyprland` to `Interface`
- [x] `Shell/Theme.qml`: load `tokens.json`, hot reload on change, expose tokens
- [x] `scripts/base16-to-tokens.py`: Base16 YAML → tokens.json
- [x] First-class themes: catppuccin-mocha, gruvbox-dark, tokyo-night, rose-pine, nord, everforest-dark
- [x] `Shell/PluginHost.qml`: scan dirs, validate manifests, mount slots
- [x] Core bar plugins: workspaces, window-title, clock, audio, network, bluetooth, battery, tray, resources, notifications
- [x] OSD (volume/brightness)
- [x] `install/install.sh` end-to-end on Arch, Fedora, Ubuntu (distrobox)
- [x] README GIF
- [ ] AUR `kotilo-shell-git` publish (PKGBUILD builds; blocked: AUR registration paused as of 2026-11-01, watch aur-general / Arch news; also needs an AUR SSH key. Restore `paru -S kotilo-shell-git` in README after publishing)

## 0.2 — Palette + notifications + control center

- [x] Palette core and Apps provider (ADR-0008): window, fuzzy ranking, Tab actions, IPC
- [x] Palette providers: Windows, Projects, Themes, Clipboard
- [x] Notification daemon (ADR-0002): never takes the D-Bus name from Omarchy's shell
- [x] Control center (ADR-0009): Wi-Fi, Bluetooth, do not disturb and power tiles, sliders, per-app audio, theme swatches, media

## 0.3 — Dev modules + agents + focus + propagation

- [x] Git, Containers and Ports bar modules (ADR-0010)
- [x] Agent protocol (ADR-0003), `bar.agents`, approvals with keyboard Allow/Deny, `scripts/kotilo-agent`
- [x] Focus Mode: Pomodoro, DND except approvals, compact bar, control center tile
- [x] Theme propagation targets (ADR-0011): `theme.target` slot, ghostty and kitty; more apps from SPEC §4.3 in the parking lot
- [x] Plugin API v1 (ADR-0012): script plugins, `Shell.openPopup`, `Shell.registerPaletteAction`, tooltips, `notification.handler`, docs match the code

## Parking lot
- More theme targets from SPEC §4.3, and a real render check in ghostty and kitty, which the dev machine does not have
- One broken service file disables every plugin, because all of them import the services module
- Control center tiles for night light, VPN and screen share (need a compositor-neutral backend)
- Keyboard access to a notification's second action
- Adapters for agent CLIs (Claude Code hooks first) and the agents list in the control center
- Memory budget: 150 MB RSS cannot be met, because an empty Quickshell with one window is 208 MB RSS (108 MB PSS). Kotilo is 247 MB RSS, 137 MB PSS. Decide whether the budget should be PSS. Opening a panel adds about 35 MB PSS that stays; the image cache is not the cause
- CPU sparkline and net up/down in `bar.resources` (SPEC §3.1)
- Keyboard access to bar plugins (definition of done)
- Vertical bar option
- Sway adapter
