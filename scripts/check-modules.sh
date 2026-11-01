#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Checks that this Quickshell build has every module the services import. One missing module
# stops the whole shell with no bar, so this says which one. Extra module names may be passed.
# Exit: 0 all present, 1 something is missing (named on stderr), 2 could not tell.
set -uo pipefail
# Terminals inside an AppImage (such as Kotilo Desktop) leak its libraries, which breaks qs.
if [[ -n "${APPIMAGE:-}" ]]; then unset LD_LIBRARY_PATH QT_PLUGIN_PATH PYTHONHOME PYTHONPATH; fi
ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

command -v qs >/dev/null 2>&1 || exit 2
modules="$(grep -hoE '^import Quickshell(\.[A-Za-z]+)+' "$ROOT"/services/*.qml | cut -d' ' -f2 | sort -u)"
[[ -n "$modules" ]] || exit 2

dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
{
  echo 'import QtQuick'
  echo 'import Quickshell'
  echo 'ShellRoot {'
  echo '    id: root'
  echo '    Component.onCompleted: {'
  echo '        const missing = ['"$(printf '"%s",' $modules "$@")"'].filter(m => {'
  echo '            try { Qt.createQmlObject("import " + m + "\nimport QtQuick\nQtObject {}", root).destroy(); return false; }'
  echo '            catch (e) { return true; }'
  echo '        });'
  echo '        console.warn("kotilo-modules:" + missing.join(" "));'
  echo '        Qt.quit();'
  echo '    }'
  echo '}'
} > "$dir/shell.qml"

result="$(timeout 5 qs -p "$dir" 2>&1 | grep -m1 -o 'kotilo-modules:.*')"
[[ -n "$result" ]] || exit 2
missing="${result#kotilo-modules:}"
[[ -z "$missing" ]] && exit 0
echo "kotilo-shell: this Quickshell build lacks: $missing" >&2
echo "kotilo-shell: the shell cannot start without it. Install a full Quickshell build; see install/deps.sh." >&2
exit 1
