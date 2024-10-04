#!/bin/sh
set -euf

# git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"
git_dir="$HOME/git/homelab"

# disable-swap.sh is skipped, because with it this RPi frequently freezes during heavy operation (such as docker-builds)

sh "$git_dir/.utils/startup-helpers/rfkill.sh"
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" 'macvlan-shim' '10.1.21.0' '10.1.20.0'
