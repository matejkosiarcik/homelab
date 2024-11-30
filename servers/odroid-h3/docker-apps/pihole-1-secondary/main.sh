#!/bin/sh
set -euf

cd "$(dirname "$0")"

# shellcheck disable=SC2068
bash "$(git rev-parse --show-toplevel)/.utils/deployment-helpers/docker-app-main.sh" $@
