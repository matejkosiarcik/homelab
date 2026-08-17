#!/bin/sh
set -euf

if [ "${CERTBOT_REMAINING_CHALLENGES-}" != '0' ]; then
    printf 'There should be 0 remaining challenges, but found: %s\n' "$CERTBOT_REMAINING_CHALLENGES" >&2
    exit 1
fi
