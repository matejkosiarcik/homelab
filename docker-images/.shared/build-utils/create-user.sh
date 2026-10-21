#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N' 2>&1)"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

if [ -z "${GID+x}" ]; then
    printf '%s [ERROR]: GID undefined\n' "$(date "${datetime_format}")" >&2
    exit 1
fi

if [ -z "${UID+x}" ]; then
    printf '%s [ERROR]: UID undefined\n' "$(date "${datetime_format}")" >&2
    exit 1
fi

# Determine nologin shell
nologinshell="$(getent passwd nobody | cut -d: -f7)"
if printf '%s' "${nologinshell}" | grep -vE '/nologin$' >'/dev/null' 2>&1; then
    printf '%s [WARNING]: Unknown nologin shell: %s\n' "$(date "${datetime_format}")" "${nologinshell}" >&2
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
