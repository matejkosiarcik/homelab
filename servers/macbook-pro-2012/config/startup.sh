#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$HOME/git/homelab")"

# sh "$git_dir/utils/startup-helpers/disable-swap.sh"
sh "$git_dir/utils/startup-helpers/rfkill.sh"

seq 1 255 | while read -r i; do
    sh "$git_dir/.utils/startup-helpers/create-eth-interface-bridge.sh" "$i" "10.1.18.$i"
done
