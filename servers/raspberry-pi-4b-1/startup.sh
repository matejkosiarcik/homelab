#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/machine-startup-helpers/disable-swap.sh"
sh "$git_dir/.utils/machine-startup-helpers/macvlan-router.sh" macvlan-shim-1 10.1.13.1 10.1.12.1
sh "$git_dir/.utils/machine-startup-helpers/macvlan-router.sh" macvlan-shim-2 10.1.13.2 10.1.12.2
sh "$git_dir/.utils/machine-startup-helpers/macvlan-router.sh" macvlan-shim-3 10.1.13.3 10.1.12.3
sh "$git_dir/.utils/machine-startup-helpers/macvlan-router.sh" macvlan-shim-4 10.1.13.4 10.1.12.4