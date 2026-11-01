#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The local repository scan must report status, and must not run a program a repository's config names.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
dir="$(mktemp -d)"; trap 'rm -rf "$dir"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
git init -q -b main "$dir/repos/plain"
git -C "$dir/repos/plain" -c user.name=t -c user.email=t@t commit -q --allow-empty -m first
echo x > "$dir/repos/plain/new.txt"
git init -q -b main "$dir/repos/hostile"
printf '#!/bin/sh\ntouch "%s/ran"\n' "$dir" > "$dir/evil.sh"; chmod +x "$dir/evil.sh"
git -C "$dir/repos/hostile" config core.fsmonitor "$dir/evil.sh"
out="$(sh "$ROOT/plugins/core/dash.github/local-repos.sh" "$dir/repos" "$dir/does-not-exist")"
grep -q '^### .*/plain$' <<<"$out" || { echo "  plain repository missing"; exit 1; }
grep -q '^### .*/hostile$' <<<"$out" || { echo "  hostile repository missing"; exit 1; }
grep -q '^? new.txt$' <<<"$out" || { echo "  change not reported"; exit 1; }
[[ ! -e "$dir/ran" ]] || { echo "  a repository ran a program"; exit 1; }
# A control: plain git status does run it, so this test can fail.
git -C "$dir/repos/hostile" status >/dev/null 2>&1 || true
[[ -e "$dir/ran" ]] || { echo "  the control did not run, so the check above proved nothing"; exit 1; }
echo "  local repository scan ok"
