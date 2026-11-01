#!/usr/bin/env bash
# Development loop: run the shell from this checkout with live reload and tail its log.
# Quickshell reloads QML on file change by itself; this script adds env, logging and clean restarts.
set -euo pipefail
# Terminals inside an AppImage (such as Kotilo Desktop) leak its libraries, which breaks qs.
if [[ -n "${APPIMAGE:-}" ]]; then unset LD_LIBRARY_PATH QT_PLUGIN_PATH PYTHONHOME PYTHONPATH; fi
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/kotilo/shell/dev.log"
mkdir -p "$(dirname "$LOG")"

export KOTILO_DEV=1
export KOTILO_LOG="${KOTILO_LOG:-debug}"
export QT_LOGGING_RULES="${QT_LOGGING_RULES:-qt.qml.*.warning=true}"

# Anchored to the program: a bare pattern would also match any command line that mentions it.
pkill -f '^(\S*/)?(qs|quickshell) .*-p '"$ROOT" 2>/dev/null || true
pkill -f '^(\S*/)?(qs|quickshell) .*-c kotilo' 2>/dev/null || true

echo "==> qs -p $ROOT  (log: $LOG)"
: > "$LOG"
( qs -p "$ROOT" 2>&1 | tee -a "$LOG" ) &
QS_PID=$!
trap 'kill $QS_PID 2>/dev/null || true; pkill -f "^(\S*/)?(qs|quickshell) .*-p $ROOT" 2>/dev/null || true' EXIT

# Fail loudly on QML warnings so Claude Code sees them.
tail -n +1 -f "$LOG" | grep --line-buffered -E 'warning|error|\[kotilo\]' &
wait $QS_PID
