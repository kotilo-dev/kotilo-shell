# Contributing to Kotilo Shell

Thanks for helping. Short version: small PRs, no hardcoded colours, test on Niri *and* Hyprland.

## Setup

```bash
git clone https://github.com/kotilo-dev/kotilo-shell && cd kotilo-shell
./install/deps.sh            # Quickshell + deps for pacman/dnf/apt
./scripts/dev.sh             # runs `qs -c kotilo` with live reload + log tail
```

Reference repos for Quickshell idioms (not committed): `git clone … ref/<name>`.

## Rules

1. **Tokens only.** No colour, font or radius literals in QML outside `themes/`.
2. **Compositor through `services/wm/`.** Never call `hyprctl` or the Niri socket elsewhere.
3. **Everything is a plugin.** New visible module → `plugins/core/<id>/` with a manifest.
4. **Shell-outs through `Shell.run`.** With a timeout. Cache results.
5. **No blocking.** Nothing on the UI thread longer than a frame; use `Process`/`FileView` async.
6. **Zero QML warnings** at startup. `./scripts/test.sh` must pass.
7. **Architectural change → ADR** in `docs/adr/` (template provided) before code.

## Commit messages

`area: imperative summary` — e.g. `theme: add rose-pine tokens`, `wm/niri: handle WorkspaceActivated`, `docs: plugin security section`.

## Pull requests

- One topic per PR. Link the TODO/issue.
- Screenshots or a short GIF for anything visual, in at least two themes (one light, one dark).
- Tested on: list compositor(s) and distro(s).
- Update `CHANGELOG.md` under *Unreleased*.

## Themes and plugins from the community

- Themes: see `docs/THEMES.md` §7. Upstream palette is the source of truth.
- Plugins: publish in your own repo; submit the manifest to `kotilo-dev/kotilo-plugins` for the index.

## Code of conduct

Be kind, assume good faith, keep it technical.
