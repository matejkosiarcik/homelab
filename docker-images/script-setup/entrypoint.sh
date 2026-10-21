#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

printf 'starting\n' >'/homelab/tmpfs/status.txt'

printf '%s [INFO]: Starting setup\n' "$(date "${datetime_format}")" >&2
sh '/homelab/setup.sh'
printf '%s [INFO]: Finished setup\n' "$(date "${datetime_format}")" >&2

printf 'started\n' >'/homelab/tmpfs/status.txt'
exec sleep infinity
