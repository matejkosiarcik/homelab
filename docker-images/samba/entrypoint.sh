#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

if [ ! -d '/var/lib/samba' ]; then
    printf '%s [ERROR]: Directory "/var/lib/samba" not found\n' "$(date "${datetime_format}")" >&2
    exit 1
fi

# Test user account exists
if ! grep -Eq "^${SAMBA_GROUP}:" '/etc/group'; then
    printf '%s [ERROR]: Group %s not available\n' "$(date "${datetime_format}")" "${SAMBA_GROUP}" >&2
    exit 1
fi
if ! grep -Eq "^${SAMBA_USERNAME}:" '/etc/passwd'; then
    printf '%s [ERROR]: User %s not available\n' "$(date "${datetime_format}")" "${SAMBA_GROUP}" >&2
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
# So we continuously read it and forward it to our logfile owned by "homelab"
for samba_logfile in "${samba_default_logfile}" "${samba_smbd_logfile_original}" "${samba_statusd_logfile_original}" "${samba_exporter_logfile_original}"; do
    install --mode=0644 '/dev/null' "${samba_logfile}"
done

start_log_forwarder() {
    source_logfile="$1"
    output_logfile="$2"

    su --shell='/bin/sh' --command="/bin/sh -c 'datetime_format=\"${datetime_format}\"; while true; do
        tail -n 0 -F \"${source_logfile}\" >>\"${output_logfile}\" || {
            printf \"%s [WARNING]: Log forwarder for %s stopped; retrying in 1 second\\n\" \"\$(date \"\${datetime_format}\")\" \"${source_logfile}\" >&2
            sleep 1
        }
    done'" 'homelab' &
}

start_log_forwarder "${samba_smbd_logfile_original}" "${samba_smbd_logfile_out}"
start_log_forwarder "${samba_statusd_logfile_original}" "${samba_statusd_logfile_out}"
start_log_forwarder "${samba_exporter_logfile_original}" "${samba_exporter_logfile_out}"

config_input_file='/homelab/smb.conf'
config_output_file='/homelab/tmpfs/smb.conf'
config_temporary_file="${config_output_file}.tmp"

su --shell='/bin/sh' --command="/bin/sh -c 'envsubst -no-digit -no-unset -no-empty -i \"${config_input_file}\" -o \"${config_temporary_file}\"'" 'homelab' || {
    rm -f "${config_temporary_file}"
    printf '%s [ERROR]: An error happened during processing of %s to %s\n' "$(date "${datetime_format}")" "${config_input_file}" "${config_output_file}" >&2
    exit 1
}

su --shell='/bin/sh' --command="/bin/sh -c 'install --mode=0444 \"${config_temporary_file}\" \"${config_output_file}\"'" 'homelab'
su --shell='/bin/sh' --command="/bin/sh -c 'rm -f \"${config_temporary_file}\"'" 'homelab'

# Generate user password
printf '%s\n%s\n' "${SAMBA_PASSWORD}" "${SAMBA_PASSWORD}" | smbpasswd -s -c "${config_output_file}" -a "${SAMBA_USERNAME}"

# Test config is valid before starting
testparm -s "${config_output_file}" || {
    printf '%s [ERROR]: Program "testparm -s" failed with status %s. Review samba config.\n' "$(date "${datetime_format}")" "${?}" >&2
    exit 1
}

# Start prometheus exporter in background
(sleep 1 && nohup '/homelab/bin/samba_statusd' -log-file-path "${samba_statusd_logfile_original}" -log-level Information) &
(sleep 2 && nohup '/homelab/bin/samba_exporter' -log-file-path "${samba_exporter_logfile_original}" -log-level Information -not-expose-pid-data) &

# Start samba
exec smbd --foreground --no-process-group --configfile="${config_output_file}"
