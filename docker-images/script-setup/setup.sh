#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

# Default no-op setup script for direct builds of this image
# Should be replaced by real script file during builds of production images

printf '%s [ERROR]: Placeholder script is invalid. Replace this file with the path to a real script and build again.\n' "$(date "${datetime_format}")" >&2
exit 1
