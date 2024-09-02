#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"
sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" macvlan-shim-001 10.1.11.1 10.1.10.1
