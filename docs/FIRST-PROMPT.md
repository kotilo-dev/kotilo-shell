# First Claude Code session — suggested prompts

Paste these into Claude Code in order. Each one is scoped so the result can be reviewed before moving on.

## 0. Orientation
```
Read CLAUDE.md, docs/SPEC.md and TODO.md. Summarise the architecture in 10 lines and list every `// TODO(api)` comment in the codebase with the file and the Quickshell type it refers to. Do not change anything yet.
```

## 1. Pin and verify Quickshell API
```
Install quickshell per install/deps.sh for this distro, record the installed version in CLAUDE.md under "Stack". Then, for every `// TODO(api)` comment, check the real property/signal/type name in the installed Quickshell's documentation (qs --help, /usr/share/doc, or the upstream docs for that exact version) and fix the code. Remove each TODO(api) only after the shell starts via ./scripts/dev.sh with zero QML warnings for that file.
```

## 2. Niri adapter
```
Make services/wm/Niri.qml work end-to-end on this machine: run `niri msg --json event-stream` manually, paste 3 real events into tests/fixtures/niri-events.jsonl, and make the adapter produce the normalised workspaces model described in services/wm/Interface.qml. The bar.workspaces plugin must show my workspaces and switch on click and scroll.
```

## 3. Theme engine
```
Make Shell/Theme.qml load themes/catppuccin-mocha/tokens.json and hot-reload when the file or settings.theme.id changes. Then run scripts/base16-to-tokens.py on the tokyo-night, rose-pine, nord and everforest-dark Base16 schemes from the tinted-theming repo, hand-tune each tokens.json so scripts/check-contrast.sh passes, and screenshot the bar in each.
```

## 4. Remaining 0.1 bar plugins
```
Implement bar.network, bar.bluetooth, bar.resources, bar.tray and bar.notifications-badge as core plugins following plugins/core/bar.audio as the pattern: a service singleton in services/ over the matching Quickshell service, a thin Pill in the plugin. Add each to services/qmldir and config/settings.default.json. Tick TODO.md as you go.
```

## 5. OSD + install test
```
Add the OSD (plugins/core/osd.volume-brightness) as a LazyLoader PanelWindow shown for 1.2s on volume/brightness change. Then test install/install.sh --copy inside Arch, Fedora and Ubuntu distrobox containers and fix anything that breaks. Update CHANGELOG.md.
```
