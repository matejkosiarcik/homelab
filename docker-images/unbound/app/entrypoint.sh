#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

ls -lah '/homelab/sock' >'/dev/null' # This command has to be here, it seem to help with issue `touch: cannot touch '<file>': Operation not supported`
if [ ! -e '/homelab/sock/unbound.sock' ]; then
    touch '/homelab/sock/unbound.sock'
fi

if [ ! -e '/homelab/logs/unbound.log' ]; then
    touch '/homelab/logs/unbound.log'
    chmod 0666 '/homelab/logs/unbound.log'
fi

printf '%s [INFO]: Checking config\n' "$(date "${datetime_format}")" >&2
unbound-checkconf '/homelab/unbound.conf'
printf '%s [INFO]: Config OK\n' "$(date "${datetime_format}")" >&2

printf '%s [INFO]: Starting unbound\n' "$(date "${datetime_format}")" >&2
exec unbound -v -d -c '/homelab/unbound.conf'
