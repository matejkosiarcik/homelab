#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-001 10.1.13.1 10.1.12.1
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-002 10.1.13.2 10.1.12.2
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-003 10.1.13.3 10.1.12.3
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-004 10.1.13.4 10.1.12.4
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-005 10.1.13.5 10.1.12.5
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-006 10.1.13.6 10.1.12.6
