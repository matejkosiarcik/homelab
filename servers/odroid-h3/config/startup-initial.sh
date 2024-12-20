#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel || printf '%s\n' "$HOME/git/homelab")"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"
sh "$git_dir/.utils/startup-helpers/rfkill.sh"
# sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" 'macvlan-shim' '10.1.11.0' '10.1.10.0'

seq 0 255 | while read -r i; do
    sh "$git_dir/.utils/startup-helpers/create-eth-interface-bridge.sh" "$i" "10.1.10.$i"
done

sh "$(dirname "$0")/startup-always.sh"
