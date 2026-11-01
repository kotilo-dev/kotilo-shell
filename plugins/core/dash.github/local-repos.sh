#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Status of the git repositories under the folders given. Read-only: optional locks are off, and
# core.fsmonitor is off because a repository's own config could otherwise run a program on status.
find -L "$@" -maxdepth 4 -name .git -prune -printf '%h\n' 2>/dev/null | head -n 40 | while IFS= read -r dir; do
    printf '### %s\n' "$dir"
    printf 'time %s\n' "$(git -c core.fsmonitor=false -C "$dir" log -1 --format=%ct 2>/dev/null)"
    printf 'remote %s\n' "$(git -c core.fsmonitor=false -C "$dir" remote get-url origin 2>/dev/null)"
    GIT_OPTIONAL_LOCKS=0 git -c core.fsmonitor=false -C "$dir" status --porcelain=v2 --branch 2>/dev/null
done
