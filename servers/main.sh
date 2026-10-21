#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

if [ "${#}" -lt 1 ]; then
    printf '%s [ERROR]: Not enough arguments.\n' "$(date "${datetime_format}")" >&2
    exit 1
fi

command="${1}"
shift

find '.' -mindepth 1 -maxdepth 1 -type d -not -name '.*' | sort | while read -r server; do
    cd "${server}" >'/dev/null'
    # shellcheck disable=SC2068
    task "${command}" ${@}
    cd - >'/dev/null'
done
