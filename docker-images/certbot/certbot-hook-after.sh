#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

if [ "${CERTBOT_REMAINING_CHALLENGES-}" != '0' ]; then
    printf '%s [ERROR]: There should be 0 remaining challenges, but found: %s\n' "$(date "${datetime_format}")" "${CERTBOT_REMAINING_CHALLENGES}" >&2
    exit 1
fi
