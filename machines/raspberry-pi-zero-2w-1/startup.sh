#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

# disable-swap.sh is skipped, because with it this RPi frequently freezes during heavy operation (such as docker-builds)

sh "$git_dir/utils/machine-startup/macvlan-router.sh" macvlan-shim-1 10.1.19.1 10.1.18.1
