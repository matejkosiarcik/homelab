#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/utils/machine-startup-helpers/disable-swap.sh"

sh "$git_dir/utils/machine-startup-helpers/macvlan-router.sh" macvlan-shim-1 10.1.17.1 10.1.16.1
sh "$git_dir/utils/machine-startup-helpers/macvlan-router.sh" macvlan-shim-2 10.1.17.2 10.1.16.2
sh "$git_dir/utils/machine-startup-helpers/macvlan-router.sh" macvlan-shim-3 10.1.17.3 10.1.16.3
# TODO: Finish setup for all necessary macvlan routers
