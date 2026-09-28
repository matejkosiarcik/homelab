#!/bin/sh
set -euf

# Samba has 2 stage entrypoint
# This is 1st stage, which runs under user "root"
# Because `samba_statusd` cannot run under different user and `samba_exporter` has to run under the same user to access it's data

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

samba_smbd_logfile_original='/var/log/samba_smbd/samba_smbd.log'
samba_statusd_logfile_original='/var/log/samba_statusd/samba_statusd.log'
samba_exporter_logfile_original='/var/log/samba_exporter/samba_exporter.log'

samba_smbd_logfile_out='/homelab/logs/samba_smbd/samba_smbd.log'
samba_statusd_logfile_out='/homelab/logs/samba_statusd/samba_statusd.log'
samba_exporter_logfile_out='/homelab/logs/samba_exporter/samba_exporter.log'

# Setup log redirection
# Because the default logfile is owned by "root"
# So we continuously read it and redirect to our logfile owned by "homelab"
touch "${samba_smbd_logfile_original}" "${samba_statusd_logfile_original}" "${samba_exporter_logfile_original}"
chmod 0644 "${samba_smbd_logfile_original}" "${samba_statusd_logfile_original}" "${samba_exporter_logfile_original}"
su --shell='/bin/sh' --command="/bin/sh -c 'tail -F \"${samba_smbd_logfile_original}\" >>\"${samba_smbd_logfile_out}\"'" 'homelab' &
su --shell='/bin/sh' --command="/bin/sh -c 'tail -F \"${samba_statusd_logfile_original}\" >>\"${samba_statusd_logfile_out}\"'" 'homelab' &
su --shell='/bin/sh' --command="/bin/sh -c 'tail -F \"${samba_exporter_logfile_original}\" >>\"${samba_exporter_logfile_out}\"'" 'homelab' &

# Inject user into config
sed "s~#smb-title#~${SAMBA_TITLE}~g;s~#smb-user#~${SAMBA_USERNAME}~g;s~#smb-group#~${SAMBA_GROUP}~g" <'/homelab/smb.conf' >'/homelab/tmpfs/smb.conf'
chmod 0444 '/homelab/tmpfs/smb.conf'
chown 'homelab:homelab' '/homelab/tmpfs/smb.conf'

# Generate user password
printf '%s\n%s\n' "${SAMBA_PASSWORD}" "${SAMBA_PASSWORD}" | smbpasswd -s -c '/homelab/tmpfs/smb.conf' -a "${SAMBA_USERNAME}"

# Test config is valid before starting
testparm -s '/homelab/tmpfs/smb.conf' || {
    printf 'Program "testparm -s" failed with status %s. Review samba config.\n' "$?" >&2
    exit 1
}

# Start prometheus exporter in background
(sleep 1 && nohup '/homelab/bin/samba_statusd' -log-file-path "${samba_statusd_logfile_original}" -log-level Information) &
(sleep 2 && nohup '/homelab/bin/samba_exporter' -log-file-path "${samba_exporter_logfile_original}" -log-level Information -not-expose-pid-data) &

# Start samba
exec smbd --foreground --no-process-group --configfile='/homelab/tmpfs/smb.conf'
