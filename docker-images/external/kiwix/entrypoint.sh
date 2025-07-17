#!/bin/sh
set -euf

zim_files_count="$(find . -mindepth 1 -maxdepth 1 -type f -name '*.zim' | wc -l)"
if [ "$zim_files_count" -eq '0' ]; then
    printf 'No "*.zim" files found\n' >&2
    exit 1
fi

zim_files="$(find '/data' -mindepth 1 -maxdepth 1 -type f -name '*.zim' | tr '\n' ' ' | sed -E 's~ $~~')"
# shellcheck disable=SC2086
kiwix-serve --port=8080 $zim_files
