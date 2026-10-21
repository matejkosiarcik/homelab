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
    printf '%s\n' "${*}" | while IFS= read -r log_message; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

# TODO: Read mode from global .env file
mode='prod'

# Pull latest git changes
if [ "$(git branch --show-current)" != 'main' ]; then
    log ERROR "$(printf 'Git repository is on branch %s instead of main, cannot update.' "$(git branch --show-current)")"
    exit 1
fi
if [ "$(git status --short)" != '' ]; then
    log ERROR "$(printf 'Git repository is dirty, cannot update. Current changes: %s' "$(git status --short)")"
    exit 1
fi
git pull --ff-only

# Run build
find docker-apps -type d -mindepth 1 -maxdepth 1 -not -name '.*' | while read -r dir; do
    task build -- --only "${dir}" "--${mode}"
done

# Run deploy
find docker-apps -type d -mindepth 1 -maxdepth 1 -not -name '.*' | while read -r dir; do
    task deploy -- --only "${dir}" "--${mode}"
done
