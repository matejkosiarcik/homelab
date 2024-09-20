#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"

seq 1 1 | while read -r index; do
    printf 'Creating macvlan-shim-router-%03d\n' "$index"
    sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" "shim-$(printf '%03d' "$index")" "10.1.15.$index" "10.1.14.$index"
done
