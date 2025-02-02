#!/bin/sh
set -euf

if [ "$#" -lt 2 ]; then
    printf 'Not enough arguments\n' >&2
    printf 'Required: <input-file> <output-file>\n' >&2
    exit 1
fi
glances_password_input_file="$1"
glances_password_output_file="$2"

glances_script_file="$(tail -n +2 <"$(dirname "$0")/entrypoint.sh")"
docker run -e "PASSWORD=$(cat "$glances_password_input_file")" --rm --entrypoint sh nicolargo/glances:latest-full -c "$glances_script_file" | tail -n 1 >"$glances_password_output_file"
