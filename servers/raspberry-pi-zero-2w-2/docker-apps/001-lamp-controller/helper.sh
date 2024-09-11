#!/bin/sh
set -euf

cd "$(dirname "$0")"

# Limit build concurrency
COMPOSE_PARALLEL_LIMIT=1
export COMPOSE_PARALLEL_LIMIT

# shellcheck disable=SC2068
bash "$(git rev-parse --show-toplevel)/.utils/deployment-helpers/helper-docker-app.sh" $@
