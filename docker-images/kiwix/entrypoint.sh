#!/bin/sh
set -euf

zim_files_count="$(find '/data' -mindepth 1 -maxdepth 1 -type f -name '*.zim' | wc -l)"
zim_files_list="$(mktemp)"

if [ "$zim_files_count" -eq '0' ]; then
    printf 'No "*.zim" files found, using empty placeholder.\n' >&2
    printf '/homelab/default-data/empty.zim\0' >>"$zim_files_list"
fi

find '/data' -mindepth 1 -maxdepth 1 -type f -name '*.zim' -print0 >>"$zim_files_list"

xargs -0 kiwix-serve --port=8080 <"$zim_files_list"
