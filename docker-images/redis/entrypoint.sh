#!/bin/sh
set -euf

config_input_file='/homelab/redis.conf'
config_output_file='/homelab/tmpfs/redis.conf'

envsubst <"${config_input_file}" >"${config_output_file}"

leftover_variables="$(envsubst --variables "$(cat "${config_output_file}")")"
if [ "${leftover_variables}" != '' ]; then
    printf 'Error: Not all variables were substituted in config file.\n' >&2
    printf 'Affected variables: %s.\n' "${leftover_variables}" >&2
    printf 'Config file (original) - %s:\n---\n%s\n---\n' "${config_input_file}" "$(cat "${config_input_file}")" >&2
    printf 'Config file (substituted) - %s:\n---\n%s\n---\n' "${config_output_file}" "$(cat "${config_output_file}")" >&2
    exit 1
fi

# Start
exec redis-server '/homelab/tmpfs/redis.conf'
