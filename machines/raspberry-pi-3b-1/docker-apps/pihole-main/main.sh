#!/bin/sh
set -euf

cd "$(dirname "$0")"

original_dir="$PWD"
export original_dir

# shellcheck disable=SC2068
sh "$(git rev-parse --show-toplevel)/utils/deployment-helpers/docker-app-main.sh" $@
