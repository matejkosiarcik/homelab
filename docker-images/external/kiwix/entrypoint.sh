#!/bin/sh
set -euf

zim_files="$(find '/data' -mindepth 1 -maxdepth 1 -type f -name '*.zim' | tr '\n' ' ' | sed -E 's~ $~~')"
# shellcheck disable=SC2086
kiwix-serve --port=8080 $zim_files
