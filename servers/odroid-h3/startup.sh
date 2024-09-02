#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"

sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-001 10.1.17.1 10.1.16.1
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-002 10.1.17.2 10.1.16.2
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-003 10.1.17.3 10.1.16.3
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-004 10.1.17.4 10.1.16.4
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-005 10.1.17.5 10.1.16.5
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-006 10.1.17.6 10.1.16.6
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-007 10.1.17.7 10.1.16.7
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-008 10.1.17.8 10.1.16.8
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-009 10.1.17.9 10.1.16.9
