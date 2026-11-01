#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# CI-friendly checks: manifests, themes, contrast, QML syntax (qmllint if available), JSON validity.
set -euo pipefail
# Terminals inside an AppImage (such as Kotilo Desktop) leak its libraries, which breaks qs.
if [[ -n "${APPIMAGE:-}" ]]; then unset LD_LIBRARY_PATH QT_PLUGIN_PATH PYTHONHOME PYTHONPATH; fi
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail=0

echo "==> JSON validity"
while IFS= read -r f; do python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" || { echo "  bad JSON: $f"; fail=1; }; done < <(find . -name '*.json' -not -path './ref/*' -not -path './node_modules/*')

echo "==> plugin manifests"
python3 -I scripts/validate-manifests.py plugins || fail=1

echo "==> theme tokens + contrast"
scripts/check-contrast.sh || fail=1

echo "==> base16 converter"
python3 -I tests/test-base16.py || fail=1

echo "==> fuzzy ranking"
if command -v node >/dev/null 2>&1; then node tests/test-fuzzy.mjs || fail=1; else echo "  node not found — skipping"; fi

echo "==> QML lint"
if command -v qmllint >/dev/null 2>&1; then
  find . -name '*.qml' -not -path './ref/*' -print0 | xargs -0 qmllint --qmldirs "$ROOT" 2>&1 | grep -v 'Warnings occurred' || true
  # qmllint cannot resolve Quickshell modules without its type info; treat as advisory for now. TODO(0.2): add Quickshell qmltypes path.
else
  echo "  qmllint not found — skipping (install qt6-declarative tools)"
fi

echo "==> shell smoke test (needs a Wayland session)"
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v qs >/dev/null 2>&1; then
  timeout 8s qs -p "$ROOT" > /tmp/kotilo-smoke.log 2>&1 || true
  # qt.qpa.services: Qt's portal registration, unrelated to QML; its text contains "Error".
  if grep -v 'qt.qpa.services' /tmp/kotilo-smoke.log | grep -Ei 'error|is not a type|cannot assign'; then echo "  QML errors above"; fail=1; else echo "  started without QML errors"; fi
else
  echo "  no Wayland session / qs — skipped"
fi

[[ $fail -eq 0 ]] && echo "ALL CHECKS PASSED" || { echo "CHECKS FAILED"; exit 1; }
