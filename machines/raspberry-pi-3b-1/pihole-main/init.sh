#!/bin/sh
set -euf

cd "$(dirname "$0")"

# shellcheck disable=SC2068
sh "$(git rev-parse --show-toplevel)/utils/init/apps/pihole/preinit.sh" $@
