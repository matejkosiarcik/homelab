#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments.\n' >&2
    exit 1
fi

command="$1"
shift

find . -mindepth 1 -maxdepth 1 -type d -not -name '.*' | sort | while read -r server; do
    cd "$server" >/dev/null
    # shellcheck disable=SC2068
    task "$command" $@
    cd - >/dev/null
done
