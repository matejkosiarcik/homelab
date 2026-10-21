#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

# TODO: Read mode from global .env file
mode='prod'

# Pull latest git changes
if [ "$(git branch --show-current)" != 'main' ]; then
    printf '%s [ERROR]: Git repository is on branch %s instead of main, cannot update.\n' "$(date "${datetime_format}")" "$(git branch --show-current)" >&2
    exit 1
fi
if [ "$(git status --short)" != '' ]; then
    printf '%s [ERROR]: Git repository is dirty, cannot update. Current changes: %s\n' "$(date "${datetime_format}")" "$(git status --short)" >&2
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
