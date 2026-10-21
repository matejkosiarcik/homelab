#!/bin/sh
set -eu

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

config_input_file='/homelab/config.txt'
config_output_file='/homelab/tmpfs/config.txt'

envsubst -no-digit -no-unset -no-empty -i "${config_input_file}" -o "${config_output_file}" || {
    printf '%s [ERROR]: An error happened during processing of %s to %s\n' "$(date "${datetime_format}")" "${config_input_file}" "${config_output_file}" >&2
    exit 1
}

cp '/homelab/rsa_key.pem' '/homelab/tmpfs/rsa_key.pem'
cp '/homelab/rsa_key.pem.pub' '/homelab/tmpfs/rsa_key.pem.pub'

# shellcheck disable=SC2068
exec wayvnc --config "${config_output_file}" ${@}
