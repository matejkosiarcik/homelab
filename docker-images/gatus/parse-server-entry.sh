#!/bin/sh
set -euf

server_dir_path="$(realpath "${1}")"
output_filepath="$(realpath "${2}")"

server_name="$(yq --raw-output '.server.name' "${server_dir_path}/config/config.yml")"
if [ "${server_name}" = '' ] || [ "${server_name}" = 'null' ] || [ "${server_name}" = 'undefined' ]; then
    printf 'Could not get server name\n' >&2
    exit 1
fi

server_short_name_machine="$(basename "${server_dir_path}")"

{
    printf '\n'
    printf '  - name: "%s"\n' "${server_name}"
    printf '    domain: "server-%s.matejhome.com"\n' "${server_short_name_machine}"
} >>"${output_filepath}"
