#!/bin/sh
# shellcheck disable=SC2251
# Inspect executables for unnecessary baggage
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N' 2>&1)"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

if [ "${#}" -lt 1 ]; then
    printf '%s [ERROR]: Not enough arguments. Executable path not provided.\n' "$(date "${datetime_format}")" >&2
    exit 1
fi

if ! executable_info="$(file "${1}" 2>&1)"; then
    printf '%s [ERROR]: Could not inspect executable %s: %s\n' "$(date "${datetime_format}")" "${1}" "${executable_info}" >&2
    exit 1
fi

# Executables should be stripped of debug symbols
if ! printf '%s\n' "${executable_info}" | grep -i 'stripped' >'/dev/null'; then
    printf '%s [ERROR]: Executable is not stripped: %s\n' "$(date "${datetime_format}")" "${executable_info}" >&2
    exit 1
fi
if printf '%s\n' "${executable_info}" | grep -i 'not stripped\|with debuginfo' >'/dev/null'; then
    printf '%s [ERROR]: Executable contains debug symbols: %s\n' "$(date "${datetime_format}")" "${executable_info}" >&2
    exit 1
fi

# Executables should be built without BuildID - relevant for Rust and Go programs
if printf '%s\n' "${executable_info}" | grep -i 'buildid\|build-id' >'/dev/null'; then
    printf '%s [ERROR]: Executable contains a BuildID: %s\n' "$(date "${datetime_format}")" "${executable_info}" >&2
    exit 1
fi

printf '%s [INFO]: Validated executable: %s\n' "$(date "${datetime_format}")" "${executable_info}" >&2
