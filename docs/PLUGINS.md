# Kotilo Shell — Plugin Guide & API Reference (API v1, draft)

Everything visible in Kotilo Shell is a plugin, including the built-in modules under `plugins/core/`. Third-party plugins live in `~/.config/kotilo/shell/plugins/<id>/` (or `$XDG_DATA_HOME/kotilo/shell/plugins/` for packaged ones).

## 1. Anatomy

```
<id>/
  manifest.json          required
  Main.qml               QML plugins
  widget.json            script plugins (no QML)
  settings.schema.json   optional; drives the auto-generated settings form
  assets/                icons, fonts, data
  README.md
```

### manifest.json

```json
{
  "id": "bar.git",
  "name": "Git status",
  "version": "0.1.0",
  "apiVersion": "^1.0",
  "author": "kotilo",
  "description": "Branch, dirty count and ahead/behind for the focused project",
  "kind": "qml",
  "slots": ["bar.center"],
  "permissions": ["process"],
  "settingsSchema": "settings.schema.json",
  "homepage": "https://github.com/kotilo-dev/plugin-git"
}
```

| Field | Meaning |
|---|---|
| `id` | reverse-dot id; `bar.*`, `palette.*`, `theme.*`, `wm.*` prefixes are conventions, not enforced |
| `apiVersion` | semver range of the Kotilo plugin API the plugin was built against; mismatch → plugin disabled with a notification |
| `kind` | `qml` \| `script` \| `provider` |
| `slots` | where the plugin may mount (see §3) |
| `permissions` | declared capabilities: `process`, `network`, `fs:read`, `fs:write`, `dbus`. Shown to the user at install time. Not enforced technically (QML has no sandbox) — see §7 |

The JSON Schema is at `plugins/schema/manifest.schema.json`; `scripts/validate-manifests.py` checks every plugin.

## 2. Three tiers

### 2.1 Script plugin (`kind: "script"`)
No QML. `widget.json` describes a command run on an interval; its JSON stdout is rendered by the shell.

```json
{
  "exec": ["bash", "-c", "uptime -p | sed 's/up //'"],
  "interval": 60,
  "format": "json",          // or "text" — plain text becomes {text}
  "onClick": ["gnome-system-monitor"],
  "icon": "clock"
}
```

Expected stdout for `format: "json"`:

```json
{ "text": "3h 12m", "icon": "clock", "tooltip": "Up since 09:14", "class": "ok",
  "percentage": 42, "actions": [{ "label": "Restart", "exec": ["systemctl", "reboot"] }] }
```

`percentage` draws a thin meter under the widget. `actions` appear in the command palette. `timeout` in `widget.json` (seconds, default 10) stops a stuck command.

`class` maps to token colours: `ok`→success, `warn`→warning, `error`→error, `info`→info, `muted`.

### 2.2 QML widget plugin (`kind: "qml"`)
`Main.qml` is a Quickshell/QtQuick component. The host sets `plugin` (manifest and paths) and `slot` (where it was mounted) if the root item declares them. `Pill` already does; other root types declare `property var plugin: null` and `property string slot: ""`. Do not make them `required`: they are set just after creation.

```qml
import QtQuick
import qs.Shell                   // Theme, Settings, Shell, Log
import qs.services as Services    // Audio, Battery, Workspaces, ...
import qs.components              // Pill, Surface, Icon, Label

Pill {
    icon: "git-branch"
    text: Services.Git.branch
    accent: Services.Git.dirty > 0 ? Theme.state.warning : Theme.accent.primary
    onClicked: Shell.openPopup(plugin, "Popup.qml")
}
```

A plugin may ship extra QML files and open them via `Shell.openPopup(plugin, "File.qml", anchorItem)`; the host places the popup under `anchorItem`, and Esc or a click outside closes it. The file must be a plain name in the plugin's folder. Calling it again closes the popup. `Pill.tooltip` shows after a short hover.

### 2.3 Provider plugin (`kind: "provider"`)
Registers into a non-visual slot. There are no base types: each contract is a registration call or a root component (ADR-0012).

| Slot | Contract |
|---|---|
| `palette.provider` | `Shell.registerPaletteProvider(item)`; see Palette providers in §4 |
| `theme.target` | root is `C.ThemeTarget`, with `template.conf` beside `Main.qml` |
| `notification.handler` | `Shell.registerNotificationHandler(item)`: `match(n)` returns whether to act, `handle(n)` returns true to hold the popup. Runs only while Kotilo Shell is the notification daemon |

A custom bar item sizes itself with `Theme.barSize(n)` and `Theme.barFontSize`, so it follows Bar scale; `Pill` already does.

In the bar, `barGroup` in the manifest places a plugin close to others in the same group; a plugin with no group stands alone. A `Pill` icon is neutral at rest: set `fg` or `iconColor` only when the colour means something.

`wm.adapter` and `lock.widget` are reserved: manifests may name them, but nothing mounts them yet.

## 3. Slots

| Slot | Container | Notes |
|---|---|---|
| `bar.left` / `bar.center` / `bar.right` | Row in the bar | order set in `settings.slots.<slot>`; unlisted plugins follow, sorted by id |
| `controlcenter.tile` | 3-column grid | root is `C.Tile`: set `title`, `subtitle`, `icon`, `active`, `available`, handle `activated()` (ADR-0009) |
| `dashboard.card` | a grid | root is `C.Card`, with `area: ({ x, y, w, h })` as fractions of the grid, and an optional `title`. Without `area` it sits below the grid. Exists only while the panel is open, so fetch on load (ADR-0015) |
| `dashboard.tab` | tabs of the dashboard panel | root has `title`, `current` (set by the panel, so poll only while true) and `key(event)`, which returns true when it used the key (ADR-0017) |
| `lock.widget` | lock screen | below the clock |
| `osd.kind` | OSD stack | custom OSD types |
| `shell.overlay` | hidden host | plugins that own a full-screen window, such as the palette |
| `theme.target` | non-visual | root is `C.ThemeTarget` with `fileName`, plus `template.conf` (API 1.3, ADR-0011) |
| `palette.provider`, `notification.handler`, `wm.adapter` | non-visual | providers |

## 4. API (`import qs.*`, see ADR-0006)

Core and third-party plugins use the same imports. Never import the shell by file path: that creates a second copy of every singleton.

### Theme
- `Theme.tokens` — full token object (see `docs/THEMES.md`)
- Shorthands: `Theme.bg.base|mantle|crust`, `Theme.surface[0..2]`, `Theme.text.primary|secondary|muted`, `Theme.accent.primary|secondary`, `Theme.state.success|warning|error|info`, `Theme.radius.sm|md|lg`, `Theme.space.xs..xl`, `Theme.font.ui|mono|display`
- `Theme.schemeId`, `Theme.isDark`
- signal `changed()`

### Settings
- `Settings.get(pluginId, key, fallback)`, `Settings.set(pluginId, key, value)`
- `Settings.global` — the whole settings object (read-only for plugins)
- signal `changed(pluginId, key)`

### Services (singletons)
`Agents`, `Focus`, `Audio`, `Network`, `Bluetooth`, `Battery`, `Brightness`, `Power`, `Resources`, `Workspaces`, `Git`, `Agents`, `Containers`, `Ports`, `Mpris`, `Notifications`, `Clipboard`. Each exposes `ready: bool`, `error: string` and degrades gracefully when its backend is absent.

### Shell
- `Shell.openPopup(plugin, file, anchorItem?)`, `Shell.closePopups()`
- `Shell.notify({summary, body, icon, urgency, actions})`
- `Shell.registerPaletteAction(plugin, {title, icon, exec})`, `Shell.unregisterPaletteActions(plugin)`: `exec` is a function or an argv array (API 1.4)
- `Shell.run(argv, {timeout, cwd}) → Promise<{stdout, stderr, code}>` — the only sanctioned way to shell out
- `Shell.toggleControlCenter()` (API 1.2)
- A plugin with a `host` property receives the PluginHost, for hosting other slots (API 1.2)
- `Shell.version`, `Shell.apiVersion`

- `Shell.registerPaletteProvider(item)`, `Shell.unregisterPaletteProvider(item)`, `Shell.paletteDataChanged()`, `Shell.paletteOpened()`, `Shell.paletteClosed()`, `Shell.fuzzyScore(query, text)`, `Shell.fuzzyRank(query, title, keywords)` (API 1.1)

### Palette providers (API 1.1, ADR-0008)
A provider is a `kind: "provider"` plugin in `palette.provider`. It registers itself on load and unregisters on destruction:

```qml
Item {
    id: root
    property var plugin: null
    property string slot: ""
    readonly property string title: "Example"
    Component.onCompleted: K.Shell.registerPaletteProvider(root)
    Component.onDestruction: K.Shell.unregisterPaletteProvider(root)
    function items(query) {
        return [{ title: "Hello", subtitle: "optional", icon: "optional-theme-icon", keywords: "optional words",
                  actions: [{ title: "Run", run: () => K.Log.info("hello") }] }];
    }
}
```

The palette filters and ranks your rows, so return every candidate. The first action runs on `Enter`; `Tab` lists them all. `items()` runs on the UI thread on each keystroke: answer from memory and never start a process there. Refresh on the `Shell.paletteOpened()` signal, and call `Shell.paletteDataChanged()` when your data changes so an open palette updates.

Optional: a provider `priority` breaks ties, higher first. A row `score` replaces fuzzy ranking for that row, for text where a subsequence match means nothing; titles rank at 1000 and above. Providers holding private data should clear it on `Shell.paletteClosed()`.

## 5. Loading and hot reload

`Shell/PluginHost.qml` scans `plugins/core/`, `$XDG_DATA_HOME/kotilo/shell/plugins/`, `~/.config/kotilo/shell/plugins/`, validates each manifest against the schema, checks `apiVersion`, and mounts `Main.qml` into its slot(s) with `Qt.createComponent`. When two plugins share an id, the later search directory wins; an invalid plugin never replaces a valid one. Set `"enabled": false` under `settings.plugins.<id>` to turn a plugin off. A file watcher reloads a plugin when any of its files change (dev mode: `KOTILO_DEV=1`).

## 6. Distribution

Kotilo Shell is GPL-3.0-or-later, but your plugin does not have to be: plugins and themes loaded at runtime are treated as separate works and may use any licence (ADR-0001).

- `kotilo-shell plugin install <git-url | owner/repo>` clones into `~/.config/kotilo/shell/plugins/<id>`
- `kotilo-shell plugin list|update|remove`
- Index (planned for 0.4): `github.com/kotilo-dev/kotilo-plugins`, a JSON list of manifests for the in-shell Plugin Store
- After editing a plugin, run `qs -c kotilo ipc call plugins reload`

## 7. Security model (read this before publishing)

QML cannot be sandboxed. A plugin can run any process the user can. Kotilo therefore:
1. shows declared `permissions` before install, and warns when a plugin appears to run processes without declaring `process`;
2. labels every installed plugin as *unverified* until the reviewed index arrives with the Plugin Store (0.4);
3. never auto-updates plugins.
Users should treat installing a plugin like installing a package.

## 8. Checklist before publishing a plugin

- [ ] `manifest.json` validates (`scripts/validate-manifests.py path/`)
- [ ] no hardcoded colours/fonts; uses `Theme.*`
- [ ] renders in light and dark themes
- [ ] keyboard reachable when interactive: `Pill` is; a custom bar item sets `activeFocusOnTab` and calls `Shell.barKey(event, item)` (ADR-0014)
- [ ] `settings.schema.json` for every user-facing option
- [ ] README with screenshot
