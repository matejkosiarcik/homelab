#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel || printf '%s\n' "$HOME/git/homelab")"

find "$git_dir/servers/.current/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | while read -r file; do
    sh "$git_dir/.utils/startup-helpers/unbound.sh" "$(basename "$file")"
done
