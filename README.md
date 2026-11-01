# Kotilo Shell

> The desktop shell for people who ship software.

Kotilo Shell is a developer-focused Wayland shell built on [Quickshell](https://quickshell.outfoxxed.me) for **Niri** and **Hyprland**. Git state, running AI coding agents, containers, open ports and focus time live in the bar, the command palette and the notification system. Every known developer colour scheme is one keypress away and propagates to your terminal, editor and tools.

Part of the [Kotilo](https://kotilo.dev) family: Kotilo Desktop (AI-agent workspace), Kotilo Launcher (Android), Kotilo Shell (Linux).

<!-- TODO: hero GIF — docs/screenshots/hero.gif -->

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/kotilo/kotilo-shell/main/install/install.sh | bash
```

Or from your distribution:

| Distro | Command |
|---|---|
| Arch | `paru -S kotilo-shell-git` |
| Fedora | `dnf copr enable kotilo/kotilo-shell && dnf install kotilo-shell` |
| NixOS / home-manager | see `packaging/nix/README.md` |
| Other | `git clone … && ./install/install.sh` |

Then add to your compositor autostart: `qs -c kotilo`.

## Compatibility

| Kotilo Shell | Quickshell | Niri | Hyprland |
|---|---|---|---|
| 0.1.x | 0.2.x | ≥ 25.08 | ≥ 0.50 |

## Features (0.1 → 1.0)

- Bar: workspaces, git, agents, containers, ports, resources, multi-timezone clock
- Command palette with pluggable providers (apps, projects, SSH, containers, processes, clipboard)
- Control center, notification daemon with agent-approval class, Focus Mode
- Theme engine: Base16/Base24 + 25 first-class themes + Material You; propagates to 20+ apps
- Plugin system: script plugins (bash + JSON), QML widgets, providers
- See `docs/SPEC.md` for the full picture.

## Develop

```bash
git clone https://github.com/kotilo/kotilo-shell && cd kotilo-shell
./install/deps.sh          # install Quickshell + runtime deps for your distro
./scripts/dev.sh           # run with live reload and log tail
```

Read `CLAUDE.md` (working agreements) and `docs/CONTRIBUTING.md`.

## Licence

TBD — see `docs/adr/0001-licence.md`.
