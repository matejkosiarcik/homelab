#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$0")" && git rev-parse --show-toplevel)"

# sh "$git_dir/.utils/startup/disable-swap.sh"
sh "$git_dir/.utils/startup/macvlan-router.sh" 10.1.6.6 10.1.16.0
