#!/bin/sh
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
    printf '%s\n' "${*}" | while IFS= read -r log_message || [ -n "${log_message}" ]; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

if [ -z "${GID+x}" ]; then
    log ERROR 'env GID unset'
    exit 1
fi

if [ -z "${UID+x}" ]; then
    log ERROR 'env UID unset'
    exit 1
fi

# Determine nologin shell
nologinshell="$(getent passwd nobody | cut -d: -f7)"
if printf '%s' "${nologinshell}" | grep -vE '/nologin$' >'/dev/null' 2>&1; then
    log WARNING "$(printf 'Unknown nologin shell: %s' "${nologinshell}")"
    nologinshell='/bin/false'
fi

# Create new homelab group
if ! getent group "${GID}" >'/dev/null' 2>&1; then
    groupadd --gid "${GID}" homelab
else
    oldgroupname="$(getent group "${GID}" | cut -d: -f1)"
    groupmod --new-name homelab "${oldgroupname}"
fi

# Create new homelab user
if ! getent passwd "${UID}" >'/dev/null' 2>&1; then
    useradd --no-log-init --home '/home/homelab' --uid "${UID}" --gid "${GID}" --shell "${nologinshell}" homelab
else
    oldusername="$(getent passwd "${UID}" | cut -d: -f1)"
    usermod --move-home --home '/home/homelab' --uid "${UID}" --gid "${GID}" --shell "${nologinshell}" --login homelab "${oldusername}"
fi

# Set correct permissions for home directory
mkdir -p '/home/homelab'
chown -R 'homelab:homelab' '/home/homelab'

# Ensure all users use the nologin shell
while IFS=":" read -r username _ _ _ _ _ _; do
    usermod --shell "${nologinshell}" "${username}"
done <'/etc/passwd'
