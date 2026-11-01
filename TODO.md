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
- [ ] Palette providers: Windows, Projects, Themes, Clipboard
- [ ] Notification daemon (ADR-0002 first; Omarchy's shell owns the D-Bus name on the dev machine)
- [ ] Control center

## Parking lot
- Memory: 0.1 already starts at 235 MB RSS against the 150 MB budget; the palette retains about 35 MB after first open
- CPU sparkline and net up/down in `bar.resources` (SPEC §3.1)
- Keyboard access to bar plugins (definition of done)
- Vertical bar option
- Sway adapter
