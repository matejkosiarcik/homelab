#!/bin/sh
set -euf

# Samba has 2 stage entrypoint
# This is 1st stage, which runs under user "root"
# Because `samba_statusd` cannot run under diffferent user and `samba_exporter` has to run under the same user to access it's data

if [ ! -d '/var/lib/samba' ]; then
    printf 'Directory "/var/lib/samba" not found\n' >&2
    exit 1
fi

# Test user account exists
if ! grep -Eq "^${SAMBA_GROUP}:" '/etc/group'; then
    printf 'Group %s not available\n' "${SAMBA_GROUP}" >&2
    exit 1
fi
if ! grep -Eq "^${SAMBA_USERNAME}:" '/etc/passwd'; then
    printf 'User %s not available\n' "${SAMBA_GROUP}" >&2
    exit 1
fi

# Setup log redirection
# Because the default logfile is owned by "root"
# So we continuously read it and redirect to our logfile owned by "homelab"
touch '/var/log/samba/smbd.log'
chmod 0644 '/var/log/samba/smbd.log'
# touch '/homelab/logs/samba/smbd.log'
# chown 'homelab:homelab' '/homelab/logs/samba/smbd.log'
# install -o homelab -g homelab -m 0644 '/dev/null' '/homelab/logs/samba/smbd.log'
su --shell='/bin/sh' --command="/bin/sh -c 'tail -F /var/log/samba/smbd.log >>/homelab/logs/samba/smbd.log" 'homelab' &

# Inject user into config
sed "s~#smb-title#~${SAMBA_TITLE}~g;s~#smb-user#~${SAMBA_USERNAME}~g;s~#smb-group#~${SAMBA_GROUP}~g" <'/homelab/smb.conf' >'/homelab/tmpfs/smb.conf'
chmod 0444 '/homelab/tmpfs/smb.conf'
chown 'homelab:homelab' '/homelab/tmpfs/smb.conf'

# Generate user password
printf '%s\n%s\n' "${SAMBA_PASSWORD}" "${SAMBA_PASSWORD}" | smbpasswd -s -c '/homelab/tmpfs/smb.conf' -a "${SAMBA_USERNAME}"
# chown -R 'homelab:homelab' '/var/lib/samba' '/var/log/samba' # '/homelab/logs/samba' '/homelab/tmpfs/samba'

# Test config is valid before starting
testparm -s '/homelab/tmpfs/smb.conf' || {
    printf 'Program "testparm -s" failed with status %s. Review samba config.\n' "$?" >&2
    exit 1
}

# Start prometheus exporter in background
(sleep 1 && nohup '/homelab/bin/samba_statusd') &
(sleep 2 && nohup '/homelab/bin/samba_exporter' -not-expose-pid-data) &

# Start samba
exec smbd --foreground --no-process-group --configfile='/homelab/tmpfs/smb.conf'
