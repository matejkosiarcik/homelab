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

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

if [ "${#}" -lt 1 ]; then
    log ERROR 'Not enough arguments. Executable path not provided.'
    exit 1
fi

if ! executable_info="$(file "${1}" 2>&1)"; then
    log ERROR "$(printf 'Could not inspect executable %s: %s' "${1}" "${executable_info}")"
    exit 1
fi

# Executables should be stripped of debug symbols
if ! printf '%s\n' "${executable_info}" | grep -i 'stripped' >'/dev/null'; then
    log ERROR "$(printf 'Executable is not stripped: %s' "${executable_info}")"
    exit 1
fi
if printf '%s\n' "${executable_info}" | grep -i 'not stripped\|with debuginfo' >'/dev/null'; then
    log ERROR "$(printf 'Executable contains debug symbols: %s' "${executable_info}")"
    exit 1
fi

# Executables should be built without BuildID - relevant for Rust and Go programs
if printf '%s\n' "${executable_info}" | grep -i 'buildid\|build-id' >'/dev/null'; then
    log ERROR "$(printf 'Executable contains a BuildID: %s' "${executable_info}")"
    exit 1
fi

log INFO "$(printf 'Validated executable: %s' "${executable_info}")"
