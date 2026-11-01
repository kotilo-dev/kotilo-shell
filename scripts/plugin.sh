#!/usr/bin/env bash
# kotilo-shell plugin <install|list|update|remove> — manages ~/.config/kotilo/shell/plugins
set -euo pipefail
DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kotilo/shell/plugins"
mkdir -p "$DIR"

usage() { echo "usage: kotilo-shell plugin install <git-url|owner/repo> | list | update [id] | remove <id>"; exit 1; }

case "${1:-}" in
  install)
    src="${2:-}"; [[ -n "$src" ]] || usage
    [[ "$src" == */* && "$src" != http* && "$src" != git@* ]] && src="https://github.com/$src"
    tmp=$(mktemp -d); git clone --depth 1 "$src" "$tmp/p" >/dev/null
    [[ -f "$tmp/p/manifest.json" ]] || { echo "no manifest.json in repo"; rm -rf "$tmp"; exit 1; }
    id=$(jq -r .id "$tmp/p/manifest.json"); perms=$(jq -r '.permissions // [] | join(", ")' "$tmp/p/manifest.json")
    echo "Plugin: $id  ($(jq -r .name "$tmp/p/manifest.json") $(jq -r .version "$tmp/p/manifest.json"))"
    echo "Declared permissions: ${perms:-none}"
    echo "Source is UNVERIFIED unless listed in kotilo/kotilo-plugins. QML plugins can run any command you can."
    read -r -p "Install? [y/N] " a; [[ "$a" == [yY] ]] || { rm -rf "$tmp"; exit 1; }
    rm -rf "$DIR/$id"; mv "$tmp/p" "$DIR/$id"; rm -rf "$tmp"
    echo "installed to $DIR/$id — restart the shell: kotilo-shell restart" ;;
  list)
    for m in "$DIR"/*/manifest.json; do [[ -f "$m" ]] && printf '%-28s %-8s %s\n' "$(jq -r .id "$m")" "$(jq -r .version "$m")" "$(jq -r .description "$m")"; done ;;
  update)
    for d in "$DIR"/*/; do id=$(basename "$d"); [[ -z "${2:-}" || "$2" == "$id" ]] && [[ -d "$d/.git" ]] && { echo "== $id"; git -C "$d" pull --ff-only; }; done ;;
  remove)
    [[ -n "${2:-}" ]] || usage; rm -rf "$DIR/$2"; echo "removed $2" ;;
  *) usage ;;
esac
