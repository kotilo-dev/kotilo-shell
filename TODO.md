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
- [ ] `install/install.sh` end-to-end on Arch, Fedora, Ubuntu (distrobox)
- [ ] README GIF
- [ ] AUR `kotilo-shell-git` publish

## Parking lot
- CPU sparkline and net up/down in `bar.resources` (SPEC §3.1)
- Keyboard access to bar plugins (definition of done)
- Vertical bar option
- Sway adapter
