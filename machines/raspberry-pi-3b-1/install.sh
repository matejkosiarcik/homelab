#!/bin/sh
# shellcheck disable=SC2068
set -euf

current_machine_dir="$(cd "$(dirname "$0")" && printf '%s\n' "$PWD")"
export current_machine_dir

# shellcheck disable=SC2068
bash "$(git rev-parse --show-toplevel)/utils/install-machine.sh" $@
