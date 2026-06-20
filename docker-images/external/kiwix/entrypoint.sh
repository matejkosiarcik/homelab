#!/bin/sh
set -euf

zim_files_count="$(find '/data' -mindepth 1 -maxdepth 1 -type f -name '*.zim' | wc -l)"
if [ "$zim_files_count" -eq '0' ]; then
    printf 'No "*.zim" files found\n' >&2
    exit 1
fi

find '/data' -mindepth 1 -maxdepth 1 -type f -name '*.zim' -print0 | xargs -0 kiwix-serve --port=8080
