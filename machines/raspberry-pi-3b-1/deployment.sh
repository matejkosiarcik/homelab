#!/bin/sh
set -euf

cd "$(dirname "$0")"

machine_dir="$PWD"
export machine_dir

# shellcheck disable=SC2068
sh "$(git rev-parse --show-toplevel)/utils/deployment-helpers/helper-machine.sh" $@
