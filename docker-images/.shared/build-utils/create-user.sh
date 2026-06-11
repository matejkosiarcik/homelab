#!/bin/sh
set -euf

if [ -z "${GID+x}" ]; then
    printf 'GID undefined\n' >&2
    exit 1
fi

if [ -z "${UID+x}" ]; then
    printf 'UID undefined\n' >&2
    exit 1
fi

# Determine nologin shell
nologinshell="$(getent passwd nobody | cut -d: -f7)"
if printf '%s' "${nologinshell}" | grep -vE '/nologin$' >/dev/null 2>&1; then
    printf 'Unknown nologin shell: %s\n' "${nologinshell}" >&2
    nologinshell='/bin/false'
fi

# Create new homelab group
if ! getent group "${GID}" >'/dev/null' 2>&1; then
    groupadd --gid "${GID}" homelab
else
    oldgroupname="$(getent group "${GID}" | cut -d: -f1)"
    groupmod --new-name homelab "${oldgroupname}"
fi

# Create new home directory

# Create new homelab user
if ! getent passwd "$UID" >'/dev/null' 2>&1; then
    useradd --no-log-init --home '/home/homelab' --uid "${UID}" --gid "${GID}" --shell "${nologinshell}" homelab
else
    oldusername="$(getent passwd "$UID" | cut -d: -f1)"
    usermod --move-home --home '/home/homelab' --uid "${UID}" --gid "${GID}" --shell "${nologinshell}" --login homelab "${oldusername}"
fi

# Set correct permissions for home directory
mkdir -p /home/homelab
chown -R 'homelab:homelab' '/home/homelab'

# Ensure all users use the nologin shell
while IFS=":" read -r username _ _ _ _ _ _; do
    usermod --shell "${nologinshell}" "${username}"
done <'/etc/passwd'
