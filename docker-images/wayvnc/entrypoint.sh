#!/bin/sh
set -eu

config_input_file='/homelab/config.txt'
config_output_file='/homelab/tmpfs/config.txt'

envsubst <"${config_input_file}" >"${config_output_file}"

leftover_variables="$(envsubst --variables "$(cat "${config_output_file}")")"
if [ "${leftover_variables}" != '' ]; then
    printf 'Error: Not all variables were substituted in config file.\n' >&2
    printf 'Affected variables: %s.\n' "${leftover_variables}" >&2
    printf 'Config file (original) - %s:\n---\n%s\n---\n' "${config_input_file}" "$(cat "${config_input_file}")" >&2
    printf 'Config file (substituted) - %s:\n---\n%s\n---\n' "${config_output_file}" "$(cat "${config_output_file}")" >&2
    exit 1
fi

cp '/homelab/rsa_key.pem' '/homelab/tmpfs/rsa_key.pem'
cp '/homelab/rsa_key.pem.pub' '/homelab/tmpfs/rsa_key.pem.pub'

# shellcheck disable=SC2068
exec wayvnc --config "${config_output_file}" ${@}
