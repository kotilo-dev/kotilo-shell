# Quickshell API reference

Pinned version: **0.3.2** (rev `2b4501a`).

The authoritative API is the type info installed with Quickshell, which always matches the running version:

```
/usr/lib/qt6/qml/Quickshell/**/*.qmltypes     properties, signals, methods, enums
/usr/lib/qt6/qml/Quickshell/Io/FileView.qml   FileView is a QML wrapper
```

Prose docs: https://quickshell.outfoxxed.me/docs/types/ (check they match the pinned version).

Behaviour the type info does not show:

- Shell files load from `qs:@/qs/...`, not `file://`. Load them with `Qt.resolvedUrl`, or they get a second copy of every singleton. Pass real paths to `FileView` with `Quickshell.shellPath()`.
- `FileView` loads as soon as it has a path. With `preload: false`, `reload()` does not emit `loaded`.
- `FileView.watchChanges` cannot see a file that does not exist yet. It does detect atomic saves and deletion of an existing file.
- `Hyprland.dispatch()`-style helpers do not exist for Niri: its CLI cannot address a workspace by id, so the adapter writes JSON to `$NIRI_SOCKET` with `Socket`. Its stream state is checked against Niri 26.04.
- `Process` does not emit `exited` when the command fails to start.
- `Hyprland.workspaces` and `Hyprland.toplevels` fill asynchronously, so they are empty during startup.
- `Hyprland.activeToplevel` stays null after startup until focus next changes. `ToplevelManager.activeToplevel` is set immediately.
- `Hyprland.dispatch()` takes Lua such as `hl.dsp.focus({ workspace = "2" })` when `Hyprland.usingLua` is true, and the classic `workspace 2` form otherwise.
