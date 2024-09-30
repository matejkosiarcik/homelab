#!/bin/sh
set -euf

# git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"
git_dir="$HOME/git/homelab"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"

seq 1 255 | while read -r index; do
    sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" "macvlan-$(printf '%03d' "$index")" "10.1.13.$index" "10.1.12.$index"
done

sh "$git_dir/.utils/startup-helpers/rfkill.sh"
