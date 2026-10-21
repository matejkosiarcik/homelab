#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

cd "$(git rev-parse --show-toplevel 2>'/dev/null')/docker-images"

find '.' -type d -mindepth 2 -maxdepth 2 | while read -r dir; do
    if [ ! -f "${dir}/Dockerfile" ]; then
        continue
    fi
    docker_image_name="$(printf '%s' "${dir}" | sed -E 's~^./~~;s~/~--~g')"
    printf '%s [INFO]: Building %s as %s\n' "$(date "${datetime_format}")" "${dir}" "${docker_image_name}"
    docker build '.' --file "${dir}/Dockerfile" --tag "${docker_image_name}:nightly"
done
