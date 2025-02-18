#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$HOME/git/homelab")"

(find "$git_dir/servers/.current/other-apps/unbound" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' || true) | while read -r file; do
    sh "$git_dir/.utils/startup-helpers/unbound.sh" "$(basename "$file")"
done
