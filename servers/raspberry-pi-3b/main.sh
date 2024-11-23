#!/bin/sh
set -euf

cd "$(dirname "$0")"

# Limit build concurrency
COMPOSE_PARALLEL_LIMIT=1
export COMPOSE_PARALLEL_LIMIT

# shellcheck disable=SC2068
python3 "$(git rev-parse --show-toplevel)/.utils/deployment-helpers/server-main.py" $@
