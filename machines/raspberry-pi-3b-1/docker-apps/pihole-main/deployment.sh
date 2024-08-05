#!/bin/sh
set -euf

cd "$(dirname "$0")"

app_dir="$PWD"
export app_dir

# shellcheck disable=SC2068
sh "$(git rev-parse --show-toplevel)/utils/deployment-helpers/helper-docker-app.sh" $@
