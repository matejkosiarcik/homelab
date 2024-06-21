#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$0")" && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/startup/disable-swap.sh"
sh "$git_dir/.utils/startup/macvlan-router.sh" 10.1.6.7 10.1.17.0
