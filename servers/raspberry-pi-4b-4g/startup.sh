#!/bin/sh
set -euf

# git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"
git_dir="$HOME/git/homelab"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"
sh "$git_dir/.utils/startup-helpers/rfkill.sh"
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" 'macvlan-shim' '10.1.17.0' '10.1.16.0'
# sh "$git_dir/.utils/startup-helpers/macvlan-router2.sh" 'macvlan-shim2' '10.1.12.4' '10.1.12.3'
# sh "$git_dir/.utils/startup-helpers/add-vlan.sh"
