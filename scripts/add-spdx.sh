#!/usr/bin/env bash
# add-spdx.sh — add the SPDX licence header to every tracked source file. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."
ID="SPDX-License-Identifier: GPL-3.0-or-later"

git ls-files '*.qml' '*.js' '*.sh' '*.py' | while read -r f; do
  grep -q 'SPDX-License-Identifier' "$f" && continue
  case "$f" in *.qml|*.js) c='//' ;; *) c='#' ;; esac
  # The header goes below a shebang or `//@ pragma` lines, which must stay first.
  awk -v h="$c $ID" 'NR>1 && !d {print h; d=1}
    !d && /^(#!|\/\/@)/ {print; next}
    !d {print h; d=1}
    {print}
    END {if (!d) print h}' "$f" > "$f.spdx"
  cat "$f.spdx" > "$f"
  rm "$f.spdx"
done
