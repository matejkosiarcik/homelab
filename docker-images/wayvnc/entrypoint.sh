#!/bin/sh
set -eu

config_input_file='/homelab/config.txt'
config_output_file='/homelab/tmpfs/config.txt'

envsubst <"${config_input_file}" >"${config_output_file}"

leftover_variables="$(envsubst --variables "$(cat "${config_output_file}")")"
if [ "${leftover_variables}" != '' ]; then
    printf "Error: Not all variables were substituted in config file.\nAffected variables: %s.\nConfig file: %s\n" "${leftover_variables}" "${config_output_file}" >&2
    exit 1
fi

cp '/homelab/rsa_key.pem' '/homelab/tmpfs/rsa_key.pem'
cp '/homelab/rsa_key.pem.pub' '/homelab/tmpfs/rsa_key.pem.pub'

# shellcheck disable=SC2068
exec wayvnc --config "${config_output_file}" ${@}
