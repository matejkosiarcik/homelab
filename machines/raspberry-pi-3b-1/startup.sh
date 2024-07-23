#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/startup/disable-swap.sh"
sh "$git_dir/.utils/startup/macvlan-router.sh" 10.1.6.4 10.1.10.0
sh "$git_dir/.utils/startup/macvlan-router.sh" 10.1.6.104 10.1.10.0
sh "$git_dir/.utils/startup/macvlan-router.sh" 10.1.6.105 10.1.10.0
