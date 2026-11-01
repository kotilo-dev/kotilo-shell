# Kotilo Shell — Product & Architecture Spec

Status: draft v0.1 · Owner: Mustafa · Licence: GPL-3.0-or-later (ADR-0001)

## 1. Positioning

**Kotilo Shell is the desktop shell for people who ship software.** Where DankMaterialShell, Noctalia and Caelestia optimise for a beautiful general-purpose desktop, Kotilo optimises for the developer's working day: git state, running AI coding agents, containers, open ports and focus time are first-class citizens of the bar, the command palette and the notification system.

- Runs on **Niri** (primary) and **Hyprland** (supported); Sway/river later via the same adapter interface.
- Distro-agnostic: Arch (AUR), Fedora (COPR), NixOS (flake), everything else via `install.sh`.
- Member of the **Kotilo** family: Kotilo Desktop (AI-agent workspace, Windows/macOS), Kotilo Launcher (Android). Shared theme tokens and a shared agent-status protocol let one wallpaper produce one palette across all three, and let the Linux bar show agents running in Kotilo Desktop.

Non-goals (v1): being a full DE (no session manager, no settings for the OS), supporting X11, supporting KDE/GNOME as hosts.

## 2. Target users

1. **The tiling-WM developer** on Arch/Fedora who already uses Niri or Hyprland and wants a polished, zero-QML-editing shell.
2. **The AI-assisted developer** running Claude Code/Codex/Gemini sessions who wants approvals and status visible without alt-tabbing.
3. **The ricer** who wants every known dev colour scheme available instantly and applied to all apps at once.

## 3. Feature set

### 3.1 Bar
Top bar by default (bottom/vertical later). Three regions, each a list of plugin slots.

| Region | Default modules |
|---|---|
| Left | Kotilo logo/menu · Workspaces (Niri scrolling + Hyprland) · Active window title |
| Center | Git status (branch, dirty count, ahead/behind) · Agents (running / awaiting approval) · Containers (podman/docker count) · Ports (listening dev ports, click → open in browser) |
| Right | CPU sparkline · RAM · Net up/down · Wi-Fi · Bluetooth · Audio · Battery · Multi-timezone clock · Notification bell · Tray · Pomodoro/Focus indicator |

### 3.2 Command Palette (not a launcher — a palette)
`Super+Space`. Fuzzy search across **providers**; every row has a primary action and a `Tab` action menu.

Built-in providers: Apps · Projects (recent repos → open in nvim/VS Code/terminal) · Windows · Themes · Wallpapers · Containers (start/stop/logs) · SSH hosts (`~/.ssh/config`) · Processes (kill, esp. port holders) · Clipboard history (syntax-highlighted code snippets) · Emoji · Calculator · Snippets · Shell command · Shell settings. Footer shows provider/plugin counts and key hints.

### 3.3 Control Center
Quick tiles (Wi-Fi, Bluetooth, DND, Night light, Focus Mode, Power profile, VPN, Screen share) · Audio (per-app) and brightness sliders · Theme switcher with swatches · Agents list (from Kotilo Desktop protocol) · Media card.

### 3.4 Notifications
Notification daemon (replaces mako/swaync). Grouping per app, per-app rules, history. **Agent approval notifications** are a distinct priority class with inline Allow/Deny that is routed back to the agent via the protocol.

### 3.5 Focus Mode
One toggle: start Pomodoro, enable DND (except agent approvals), compact bar, optional mute. Session stats in the dashboard.

### 3.6 Other modules
Lock screen · Logout menu · OSD (volume/brightness/caps) · Wallpaper manager (+ matugen) · Workspace overview grid · Scratchpad drop-down terminal · Keybinding cheat-sheet overlay · Screenshot + annotate · Dev dashboard (calendar, todo.txt/Taskwarrior, open PRs via `gh`, CI status, weather) · Monitor profiles (laptop / desk / presentation, auto on hotplug) · Settings GUI with live preview.

## 4. Theme engine

### 4.1 Model
Three layers:
1. **Scheme** — 16/24 raw colours. Source: Base16/Base24 YAML (tinted-theming), first-class theme files, or matugen output.
2. **Tokens** — semantic names the UI uses: `bg.base/mantle/crust`, `surface.0/1/2`, `text.primary/secondary/muted`, `accent.primary/secondary`, `state.success/warning/error/info`, `radius.sm/md/lg`, `space.*`, `font.ui/mono/display`.
3. **App templates** — Jinja-like templates per external app, rendered on theme change.

Base16 schemes map onto tokens automatically (base00→bg, base0D→accent, …). **First-class themes** ship hand-tuned tokens because Base16's 16 colours cannot express their surface hierarchies.

### 4.2 Bundled first-class themes
Catppuccin (Latte/Frappé/Macchiato/Mocha) · Gruvbox (dark/light × hard/medium/soft, Material) · Tokyo Night (Night/Storm/Moon/Day) · Rosé Pine (Main/Moon/Dawn) · Nord · Dracula · Everforest (dark/light × hard/soft) · Kanagawa (Wave/Dragon/Lotus) · One Dark · Solarized (dark/light) · Monokai Pro · Ayu (Dark/Mirage/Light) · Nightfox family · GitHub (Dark/Dimmed/Light) · Vesper · Oxocarbon · Cyberdream · Flexoki · Poimandres · Modus (Vivendi/Operandi) · Night Owl · Palenight · **Kotilo Dynamic** (matugen from wallpaper, Material You).

Plus: any Base16/Base24 scheme by name, Omarchy theme folder import, auto light/dark by time or sunrise.

### 4.3 Propagation targets (v1)
Shell · ghostty · kitty · alacritty · foot · Neovim (generates a colorscheme) · VS Code (`settings.json` theme switch) · GTK 3/4 · Qt (qt6ct) · btop · fzf · bat · starship · cava · yazi · lazygit · Vencord · Firefox userChrome · wallpaper (swww). Each target is a plugin; users can add their own template.

## 5. Plugin system

### 5.1 Anatomy
```
~/.config/kotilo/shell/plugins/<id>/
  manifest.json          id, name, version, author, apiVersion, slots[], permissions[], settingsSchema
  Main.qml               for QML plugins
  widget.json            for script plugins (no QML)
  assets/
```

### 5.2 Three tiers
1. **Script plugin** — a command run on an interval that prints JSON `{text, icon, tooltip, class, percentage, actions[]}`; the shell renders it. Bash-only bar modules in 20 lines.
2. **QML widget plugin** — full Quickshell component with access to the `Kotilo.*` API; may open popups.
3. **Provider plugin** — adds a palette search provider, a theme propagation target, a notification handler, or a compositor adapter.

### 5.3 Slots
`bar.left/center/right` · `controlcenter.tile` · `dashboard.card` · `palette.provider` · `notification.handler` · `lock.widget` · `osd.kind` · `theme.target` · `wm.adapter`.

### 5.4 API (`import qs.*`, ADR-0006)
- `Kotilo.Theme` — tokens, active scheme, `changed` signal
- `Kotilo.Services` — Audio, Network, Bluetooth, Battery, Brightness, Workspaces, Git, Agents, Containers, Ports, Mpris, Notifications
- `Kotilo.Settings` — namespaced per plugin, auto-generated settings form from schema
- `Kotilo.Shell` — `openPopup()`, `notify()`, `registerPaletteAction()`, `run()`
- `apiVersion` semver check at load; incompatible plugins are disabled with a notification.

### 5.5 Loading, hot reload, distribution
`Loader`/`Qt.createComponent` into the slot container; file watcher reloads a plugin on change. `kotilo-shell plugin install <git-url | owner/repo>`; central `kotilo-plugins` index repo; Plugin Store inside the palette.

### 5.6 Security (be honest in docs)
QML has no sandbox. Manifest declares permissions (process, network, filesystem) shown at install; index-listed plugins are reviewed; non-index sources show a warning. Core modules use the same API, so the API is always complete enough.

## 6. Architecture

```
shell.qml
 └─ Shell/PluginHost        discovers plugins, validates manifests, mounts slots
 └─ Shell/ThemeEngine       scheme → tokens → QML singleton + template render
 └─ Shell/Settings          settings.json watcher, schema validation
 └─ Shell/IPC               `kotilo-shell` CLI socket + Kotilo agent protocol (Unix socket, JSON lines)
 └─ services/*              singletons over Quickshell services (Pipewire, UPower, NetworkManager, Mpris, Tray, Notifications) and external tools (git, podman, ss)
 └─ services/wm/            Interface.qml + Niri.qml (event stream) + Hyprland.qml (socket2)
 └─ plugins/core/*          every visible module
```

Principles: singletons own state, modules are pure views; every panel is a `LazyLoader`; all shell-outs go through `Shell/Process` with timeouts and caching; no module may block the UI thread.

### Agent protocol (shared with Kotilo Desktop)
Unix socket `$XDG_RUNTIME_DIR/kotilo-agents.sock`, JSON lines. Messages: `agent.status {id, tool, project, state: running|awaiting|idle|done, since}`, `agent.approval {id, command, cwd}`, `agent.approval.reply {id, allow}`. A tiny adapter (hook/wrapper) per agent CLI publishes to the socket; Kotilo Desktop speaks the same protocol over the network.

## 7. Distribution

- Source + `install.sh` (detects dnf/pacman/apt, installs deps, places files under `~/.config/quickshell/kotilo`, writes a starter `settings.json`).
- AUR `kotilo-shell` / `kotilo-shell-git` · Fedora COPR · Nix flake with home-manager module · Debian/Ubuntu via script only.
- Quickshell version pinned per release; compatibility matrix for Niri/Hyprland versions in `README`.
- Testing matrix: Arch, Fedora, Ubuntu in distrobox containers; Niri and Hyprland on the dev machine.

## 8. Design language

- Type: Inter (UI), JetBrains Mono (data/bar), optional display face per theme.
- Shapes: 8–14 px radii, 1 px hairline borders from `surface.2`, soft 24–64 px shadows on floating panels.
- Motion: 150–220 ms ease-out; respect reduced-motion setting.
- Iconography: single stroke set (Lucide-style) tinted by tokens; no emoji in UI.
- Reference mockup: Claude Design canvas "Kotilo Shell Mockup" (bar, palette, control center, agent toast in Catppuccin Mocha and Gruvbox Dark).

## 9. Roadmap

| Version | Scope |
|---|---|
| **0.1** | Bar with default modules · ThemeEngine (Base16 + 6 first-class themes) · Niri + Hyprland adapters · OSD · install.sh · AUR-git |
| **0.2** | Command palette (apps, windows, projects, themes, clipboard) · Notification daemon · Control center |
| **0.3** | Git/Agents/Containers/Ports modules · Agent protocol + approvals · Focus Mode · Theme propagation targets · Plugin API v1 + script plugins |
| **0.4** | Settings GUI · Plugin Store · Lock screen · Dashboard · Monitor profiles · COPR + Nix |
| **1.0** | API freeze · docs site · Omarchy theme import · stability pass |

## 10. Current milestone — 0.1 checklist

- [ ] Repo skeleton per `CLAUDE.md` layout; `scripts/dev.sh`, `scripts/test.sh`
- [ ] `services/wm/Interface.qml` + Niri adapter (event stream, workspaces, focused window)
- [ ] Hyprland adapter (socket2 events)
- [ ] ThemeEngine: load Base16 YAML → tokens; `Theme` singleton; Catppuccin Mocha, Gruvbox Dark, Tokyo Night, Rosé Pine, Nord, Everforest first-class
- [ ] PluginHost with `bar.*` slots; manifest schema + validator
- [ ] Core bar plugins: workspaces, window title, clock (multi-tz), audio, network, battery, tray, cpu/ram, notifications badge
- [ ] OSD for volume/brightness
- [ ] `install/deps.sh` for pacman/dnf/apt; `install.sh`; starter `settings.json`
- [ ] README with GIF, one-command install, compatibility matrix
- [ ] AUR `kotilo-shell-git` PKGBUILD

## 11. Open decisions (ADRs to write)

- ADR-0002 Notification daemon: own implementation vs integrate swaync
- ADR-0003 Agent protocol transport: Unix socket vs D-Bus
- ADR-0004 Settings GUI: inside shell (QML) vs separate app
