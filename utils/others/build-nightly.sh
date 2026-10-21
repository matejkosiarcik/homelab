#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
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
    printf '%s\n' "${*}" | while IFS= read -r log_message || [ -n "${log_message}" ]; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

cd "$(git rev-parse --show-toplevel 2>'/dev/null')/docker-images"

find '.' -type d -mindepth 2 -maxdepth 2 | while read -r dir; do
    if [ ! -f "${dir}/Dockerfile" ]; then
        continue
    fi
    docker_image_name="$(printf '%s' "${dir}" | sed -E 's~^./~~;s~/~--~g')"
    log INFO "$(printf 'Building %s as %s' "${dir}" "${docker_image_name}")"
    docker build '.' --file "${dir}/Dockerfile" --tag "${docker_image_name}:nightly"
done
