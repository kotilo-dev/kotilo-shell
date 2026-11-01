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
- [x] Claude Code hook adapter (ADR-0013): `kotilo-agent hook claude`
- [x] Agents list in the control center; rows open the agents panel and never answer
- [x] Bar keyboard mode (ADR-0014): `ipc call bar toggle`, Pill and tray
- [x] Keyboard access to every notification action: ←→ in the panel
- [x] CPU sparkline and net down/up in `bar.resources` (SPEC §3.1)

## 0.4 — Settings, store, lock, dashboard

- [x] Settings panel (ADR-0004): forms from plugin schemas, keyboard first, saving refused while `settings.json` does not parse
- [x] General settings in the panel: theme, propagation, animations, bar position and height
- [x] Array and object settings: edited as JSON, checked against the schema
- [x] Dashboard (ADR-0015): panel, `dashboard.card` slot, Focus and pull request cards
- [ ] More dashboard cards: CI status, calendar, todo
- [ ] Plugin Store: needs the public `kotilo-plugins` index repo, which is the owner's decision
- [ ] Lock screen: needs a decision, since a bug here locks the user out or lets someone in, and Omarchy has one
- [ ] Monitor profiles
- [ ] COPR and Nix publishing

## Parking lot
- More theme targets from SPEC §4.3, and a real render check in ghostty and kitty, which the dev machine does not have
- One service that fails to compile stops the whole shell: no bar, only errors in the log. Importing a QML module depends on all its singletons, so this is Qt behaviour. `scripts/test.sh` catches a typo where it has a Wayland session. The exposure for users is a Quickshell build without an optional module (Pipewire, UPower, Bluetooth, Networking, Mpris, SystemTray, Notifications), since eight services import those at compile time. `scripts/check-modules.sh` now names a missing module at install and on `kotilo-shell start`. The full fix would be runtime-loaded backends behind each service, which needs an ADR
- Control center tiles for night light, VPN and screen share (need a compositor-neutral backend)
- Adapters for more agent CLIs
- Memory budget: 150 MB PSS, because an empty Quickshell with one window is already 208 MB RSS (108 MB PSS). In nested runs Kotilo starts at 137 MB PSS and settles at 158-170 MB after panels have been opened 12 times each, so it is over budget once used. Without panel shadows the same run settles at 152-166 MB, so shadows cost about 7 MB, within noisy runs. This is not a leak: an earlier run stayed flat over 40 reopens. A tighter glibc allocator did not help. A fresh start on the real desktop is not measured
- Vertical bar option
- Sway adapter
