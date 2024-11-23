#!/bin/sh
set -euf

cd "$(dirname "$0")"

# shellcheck disable=SC2068
python3 "$(git rev-parse --show-toplevel)/.utils/deployment-helpers/server-main.py" $@
