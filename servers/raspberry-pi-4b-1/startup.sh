#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-1 10.1.13.1 10.1.12.1
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-2 10.1.13.2 10.1.12.2
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-3 10.1.13.3 10.1.12.3
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-4 10.1.13.4 10.1.12.4
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-5 10.1.13.5 10.1.12.5
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-6 10.1.13.6 10.1.12.6
