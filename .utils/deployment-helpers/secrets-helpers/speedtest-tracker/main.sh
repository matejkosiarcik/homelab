#!/bin/sh
set -euf

currdir="$(dirname "$0")"

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n' >&2
    printf 'Required: <output-file>\n' >&2
    exit 1
fi
output_file="$1"

npx --prefix "$currdir" tsx "$currdir/src/main.ts" --output "$output_file"
