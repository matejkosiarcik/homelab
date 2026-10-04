#!/bin/sh
set -eu

config_input_file='/homelab/config.txt'
config_output_file='/homelab/tmpfs/config.txt'

envsubst -no-digit -no-unset -no-empty -i "${config_input_file}" -o "${config_output_file}" || {
    printf 'An error happened during processing of %s to %s\n\n' "${config_input_file}" "${config_output_file}" >&2
    exit 1
}

cp '/homelab/rsa_key.pem' '/homelab/tmpfs/rsa_key.pem'
cp '/homelab/rsa_key.pem.pub' '/homelab/tmpfs/rsa_key.pem.pub'

# shellcheck disable=SC2068
exec wayvnc --config "${config_output_file}" ${@}
