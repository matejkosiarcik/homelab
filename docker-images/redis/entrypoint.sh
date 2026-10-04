#!/bin/sh
set -euf

config_input_file='/homelab/redis.conf'
config_output_file='/homelab/tmpfs/redis.conf'

envsubst -no-digit -no-unset -no-empty -i "${config_input_file}" -o "${config_output_file}" || {
    printf 'An error happened during processing of %s to %s\n\n' "${config_input_file}" "${config_output_file}" >&2
    exit 1
}

# Start
exec redis-server '/homelab/tmpfs/redis.conf'
