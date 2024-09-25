#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"

seq 1 13 | while read -r index; do
    sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" "macvlan-shim-$(printf '%03d' "$index")" "10.1.17.$index" "10.1.16.$index"
done
