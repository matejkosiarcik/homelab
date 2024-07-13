#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$0")" && git rev-parse --show-toplevel)"

# Disable-Swap is skipped, because with it Pi frequently freezes during operation
# Mainly during heavy load, such as docker-builds

sh "$git_dir/.utils/startup/macvlan-router.sh" 10.1.6.7 10.1.17.0
