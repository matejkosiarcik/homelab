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

# Create new homelab group
if ! getent group "${GID}" >'/dev/null' 2>&1; then
    groupadd --gid "${GID}" homelab
else
    oldgroupname="$(getent group "${GID}" | cut -d: -f1)"
    groupmod --new-name homelab "${oldgroupname}"
fi

# Create new home directory
mkdir -p /home/homelab
chown -R "${UID}:${GID}" '/home/homelab'

# Create new homelab user
if ! getent passwd "$UID" >'/dev/null' 2>&1; then
    useradd --no-log-init --home '/home/homelab' --uid "${UID}" --gid "${GID}" --shell "${nologinshell}" homelab
else
    oldusername="$(getent passwd "$UID" | cut -d: -f1)"
    chown -R "${oldusername}:homelab" '/home/homelab'
    usermod --move-home --home '/home/homelab' --uid "${UID}" --gid "${GID}" --shell "${nologinshell}" --login homelab "${oldusername}"
fi

# Set correct permissions for home directory
chown -R 'homelab:homelab' '/home/homelab'

# Ensure all users use the nologin shell
while IFS=":" read -r username _ _ _ _ _ _; do
    usermod --shell "${nologinshell}" "${username}"
done <'/etc/passwd'

# Lock all accounts except the homelab user
while IFS=":" read -r username _ _ _ _ _ _; do
    if [ "${username}" = 'homelab' ]; then
        continue;
    fi
    usermod --lock "${username}"
    passwd -l "${username}"
    chage -E 0 "${username}"
    # pkill -u "${username}"
done <'/etc/passwd'
