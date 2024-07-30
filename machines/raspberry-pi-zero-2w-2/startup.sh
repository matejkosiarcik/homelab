#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

# Disable-Swap is skipped, because with it this RPi frequently freezes during operation
# Mainly during heavy load, such as docker-builds

sh "$git_dir/utils/machine-startup/macvlan-router.sh" macvlan-shim-1 10.1.21.1 10.1.20.1
