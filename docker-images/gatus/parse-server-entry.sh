#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

server_dir_path="$(realpath "${1}")"
output_filepath="$(realpath "${2}")"

server_name="$(yq --raw-output '.server.name' "${server_dir_path}/config/config.yml")"
if [ "${server_name}" = '' ] || [ "${server_name}" = 'null' ] || [ "${server_name}" = 'undefined' ]; then
    printf '%s [ERROR]: Could not get server name\n' "$(date "${datetime_format}")" >&2
    exit 1
fi

server_short_name_machine="$(basename "${server_dir_path}")"

{
    printf '\n'
    printf '  - name: "%s"\n' "${server_name}"
    printf '    domain: "server-%s.matejhome.com"\n' "${server_short_name_machine}"
} >>"${output_filepath}"
