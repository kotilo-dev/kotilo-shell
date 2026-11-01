#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Removes Kotilo Shell files. Keeps ~/.config/kotilo/shell (your settings, themes, plugins) unless --purge.
# Everything else under the kotilo directories belongs to Kotilo Desktop: never remove it.
set -euo pipefail
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
pkill -f '^(\S*/)?(qs|quickshell) .*-c kotilo' || true
rm -rf "$CONFIG_HOME/quickshell/kotilo"
rm -f "${XDG_BIN_HOME:-$HOME/.local/bin}/kotilo-shell"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/kotilo/shell"
if [[ "${1:-}" == "--purge" ]]; then rm -rf "$CONFIG_HOME/kotilo/shell" "${XDG_DATA_HOME:-$HOME/.local/share}/kotilo/shell"; echo "purged user config too"; fi
echo "Kotilo Shell removed. Remove the autostart line from your compositor config."
