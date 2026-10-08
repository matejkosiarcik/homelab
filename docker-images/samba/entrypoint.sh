#!/bin/sh
set -euf

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

samba_default_logfile='/var/log/samba/samba_smbd.log'
samba_smbd_logfile_original='/var/log/samba_smbd/samba_smbd.log'
samba_statusd_logfile_original='/var/log/samba_statusd/samba_statusd.log'
samba_exporter_logfile_original='/var/log/samba_exporter/samba_exporter.log'

samba_smbd_logfile_out='/homelab/logs/samba_smbd/samba_smbd.log'
samba_statusd_logfile_out='/homelab/logs/samba_statusd/samba_statusd.log'
samba_exporter_logfile_out='/homelab/logs/samba_exporter/samba_exporter.log'

# Setup log redirection
# Because the default logfile is owned by "root"
# So we continuously read it and redirect to our logfile owned by "homelab"
for samba_logfile in "${samba_default_logfile}" "${samba_smbd_logfile_original}" "${samba_statusd_logfile_original}" "${samba_exporter_logfile_original}"; do
    install --mode=0644 '/dev/null' "${samba_logfile}"
done
su --shell='/bin/sh' --command="/bin/sh -c 'tail -F \"${samba_smbd_logfile_original}\" >>\"${samba_smbd_logfile_out}\"'" 'homelab' &
su --shell='/bin/sh' --command="/bin/sh -c 'tail -F \"${samba_statusd_logfile_original}\" >>\"${samba_statusd_logfile_out}\"'" 'homelab' &
su --shell='/bin/sh' --command="/bin/sh -c 'tail -F \"${samba_exporter_logfile_original}\" >>\"${samba_exporter_logfile_out}\"'" 'homelab' &

config_input_file='/homelab/smb.conf'
config_output_file='/homelab/tmpfs/smb.conf'
config_temporary_file="${config_output_file}.tmp"

su --shell='/bin/sh' --command="/bin/sh -c 'envsubst -no-digit -no-unset -no-empty -i \"${config_input_file}\" -o \"${config_temporary_file}\"'" 'homelab' || {
    rm -f "${config_temporary_file}"
    printf 'An error happened during processing of %s to %s\n\n' "${config_input_file}" "${config_output_file}" >&2
    exit 1
}

su --shell='/bin/sh' --command="/bin/sh -c 'install --mode=0444 \"${config_temporary_file}\" \"${config_output_file}\"'" 'homelab'
su --shell='/bin/sh' --command="/bin/sh -c 'rm -f \"${config_temporary_file}\"'" 'homelab'

# Generate user password
printf '%s\n%s\n' "${SAMBA_PASSWORD}" "${SAMBA_PASSWORD}" | smbpasswd -s -c "${config_output_file}" -a "${SAMBA_USERNAME}"

# Test config is valid before starting
testparm -s "${config_output_file}" || {
    printf 'Program "testparm -s" failed with status %s. Review samba config.\n' "${?}" >&2
    exit 1
}

# Start prometheus exporter in background
(sleep 1 && nohup '/homelab/bin/samba_statusd' -log-file-path "${samba_statusd_logfile_original}" -log-level Information) &
(sleep 2 && nohup '/homelab/bin/samba_exporter' -log-file-path "${samba_exporter_logfile_original}" -log-level Information -not-expose-pid-data) &

# Start samba
exec smbd --foreground --no-process-group --configfile="${config_output_file}"
