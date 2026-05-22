#!/bin/sh
set -euf

# Determine nologin shell
nologinshell=''
if [ -e '/usr/sbin/nologin' ]; then
    nologinshell='/usr/sbin/nologin'
elif [ -e '/sbin/nologin' ]; then
    nologinshell='/sbin/nologin'
else
    nologinshell='/bin/false'
fi

# Create new "homelab" group
if ! getent group "${GID}" >/dev/null 2>&1; then
    groupadd --gid "${GID}" homelab
else
    oldgroupname="$(getent group "${GID}" | cut -d: -f1)"
    groupmod --new-name homelab "${oldgroupname}"
fi

# Create new "homelab" user
if ! getent passwd "$UID" >/dev/null 2>&1; then
    useradd --no-log-init --home /home/homelab --uid "${UID}" --gid "${GID}" --shell "${nologinshell}" homelab
else
    oldusername="$(getent passwd "$UID" | cut -d: -f1)"
    usermod --move-home --home /home/homelab --uid "${UID}" --gid "${GID}" --shell "${nologinshell}" --login homelab "${oldusername}"
fi

# Create "homelab" home directory
mkdir -p /home/homelab
chown -R homelab:homelab /home/homelab
