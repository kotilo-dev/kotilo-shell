#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs Kotilo Shell for the current user.
#   - from a clone:  ./install/install.sh
#   - via curl:      curl -fsSL https://raw.githubusercontent.com/kotilo-dev/kotilo-shell/main/install/install.sh | bash
# Layout: shell files -> $XDG_CONFIG_HOME/quickshell/kotilo ; user config -> $XDG_CONFIG_HOME/kotilo/shell
set -euo pipefail

REPO_URL="https://github.com/kotilo-dev/kotilo-shell"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
QS_DIR="$CONFIG_HOME/quickshell/kotilo"
KOTILO_DIR="$CONFIG_HOME/kotilo/shell"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
MODE="symlink"   # symlink (dev) | copy (release)

for a in "$@"; do case "$a" in --copy) MODE="copy";; --symlink) MODE="symlink";; -h|--help) sed -n '2,6p' "$0"; exit 0;; esac; done

# Resolve source: script dir if inside a clone, else clone to ~/.local/share/kotilo/shell/src
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd || true)"
if [[ -z "$SRC" || ! -f "$SRC/shell.qml" ]]; then
  SRC="${XDG_DATA_HOME:-$HOME/.local/share}/kotilo/shell/src"
  if [[ -d "$SRC/.git" ]]; then git -C "$SRC" pull --ff-only; else git clone --depth 1 "$REPO_URL" "$SRC"; fi
  MODE="copy"
fi
echo "==> source: $SRC  mode: $MODE"

command -v qs >/dev/null 2>&1 || { echo "!! quickshell (qs) not found. Run $SRC/install/deps.sh first."; exit 1; }

mkdir -p "$CONFIG_HOME/quickshell" "$KOTILO_DIR/themes" "$KOTILO_DIR/plugins" "$BIN_DIR" "${XDG_CACHE_HOME:-$HOME/.cache}/kotilo/shell"

# Shell files
if [[ "$MODE" == "symlink" ]]; then
  [[ -e "$QS_DIR" && ! -L "$QS_DIR" ]] && mv "$QS_DIR" "$QS_DIR.bak.$(date +%s)"
  ln -sfn "$SRC" "$QS_DIR"
else
  rm -rf "$QS_DIR"; mkdir -p "$QS_DIR"
  cp -r "$SRC"/{shell.qml,Shell,components,services,plugins,themes,assets,config,scripts} "$QS_DIR"/
fi

# User settings (never overwrite)
[[ -f "$KOTILO_DIR/settings.json" ]] || { cp "$SRC/config/settings.default.json" "$KOTILO_DIR/settings.json"; echo "==> wrote $KOTILO_DIR/settings.json"; }

# CLI wrapper. Not named kotilo: that is Kotilo Desktop's launcher (ADR-0005).
cat > "$BIN_DIR/kotilo-shell" <<'EOF'
#!/usr/bin/env bash
# kotilo-shell — control the running shell. Subcommands: start | restart | stop | log | theme <id> | plugin <install|list|remove> ...
set -euo pipefail
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/kotilo/shell"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/kotilo/shell/shell.log"
case "${1:-}" in
  start)   exec qs -c kotilo >>"$LOG" 2>&1 ;;
  stop)    pkill -f '^(\S*/)?(qs|quickshell) .*-c kotilo' || true ;;
  restart) pkill -f '^(\S*/)?(qs|quickshell) .*-c kotilo' || true; sleep 0.3; setsid qs -c kotilo >>"$LOG" 2>&1 < /dev/null & disown; echo restarted ;;
  log)     tail -f "$LOG" ;;
  theme)   [[ -n "${2:-}" ]] || { echo "usage: kotilo-shell theme <id>"; exit 1; }
           tmp=$(mktemp); jq --arg id "$2" '.theme.id=$id' "$CFG/settings.json" >"$tmp" && mv "$tmp" "$CFG/settings.json"; echo "theme -> $2" ;;
  plugin)  shift; exec "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/kotilo/scripts/plugin.sh" "$@" ;;
  *)       echo "usage: kotilo-shell {start|stop|restart|log|theme <id>|plugin ...}"; exit 1 ;;
esac
EOF
chmod +x "$BIN_DIR/kotilo-shell"

# Compositor autostart hints
cat <<EOF

==> Installed.
Start now:            kotilo-shell start   (or: qs -c kotilo)
Autostart — Niri:     add to ~/.config/niri/config.kdl:    spawn-at-startup "qs" "-c" "kotilo"
Autostart — Hyprland: add to hyprland.conf:                exec-once = qs -c kotilo
Make sure $BIN_DIR is on your PATH.
Settings: $KOTILO_DIR/settings.json   Themes: $KOTILO_DIR/themes/   Plugins: $KOTILO_DIR/plugins/
EOF
