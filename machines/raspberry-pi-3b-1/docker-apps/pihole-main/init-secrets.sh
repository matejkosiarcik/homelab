#!/bin/sh
set -euf

cd "$(dirname "$0")"

# shellcheck disable=SC2068
sh "$(git rev-parse --show-toplevel)/docker-apps/pihole/init-secrets.sh" $@
