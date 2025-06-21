#!/bin/sh
set -euf

currdir="$(dirname "$0")"

if [ "$#" -lt 2 ]; then
    printf 'Not enough arguments\n' >&2
    printf 'Required: <password> <output-file>\n' >&2
    exit 1
fi
password="$1"
output_file="$2"

glances_script_file="$(tail -n +2 <"$currdir/entrypoint.sh")"
docker run --rm --env "PASSWORD=$password" --entrypoint sh nicolargo/glances:latest-full -c "$glances_script_file"
docker run --rm --env "PASSWORD=$password" --entrypoint sh nicolargo/glances:latest-full -c "$glances_script_file" | tail -n 1 | sed -E 's~^.+: ~~' >"$output_file"
