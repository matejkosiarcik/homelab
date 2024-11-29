#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel || printf '%s\n' "$HOME/git/homelab")"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"
sh "$git_dir/.utils/startup-helpers/rfkill.sh"
# sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" 'macvlan-shim' '10.1.17.0' '10.1.16.0'

seq 1 255 | while read -r i; do
    sh "$git_dir/.utils/startup-helpers/ethbridge.sh" "ethbridge-$i" "10.1.16.$i"
done

sh "$(dirname "$0")/startup-always.sh"
