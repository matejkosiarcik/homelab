#!/bin/sh
set -euf

process_template() {
    input_file="${1}"
    output_file="${2}"

    if [ ! -f "${input_file}" ]; then
        printf "Error: Template file %s not found\n" "${input_file}" >&2
        exit 1
    fi

    tmpfile="$(mktemp)"
    variables_in_config="$(sed -nE 's/.*\$\{?([A-Za-z_][A-Za-z0-9_]*).*/\1/p' <"${input_file}" | sort -u || true)"

    # This is an extra step to base64 decode some variables (ending in "_ENCRYPTED")
    printf '%s\n' "${variables_in_config}" | while read -r variable; do
        value="$(printenv "${variable}" || true)"

        if printf '%s' "${variable}" | grep -E '_ENCRYPTED$' >'/dev/null' 2>&1; then
            value="$(printf '%s' "${value}" | base64 -d 2>'/dev/null')" || {
                printf 'Error: Failed to base64 decode variable %s\n' "${variable}" >&2
                exit 1
            }
            printf "export %s='%s'\n" "${variable}" "${value}" >>"${tmpfile}"
        fi
    done

    # shellcheck source=/dev/null
    . "${tmpfile}"
    rm -f "${tmpfile}"

    envsubst -no-digit -no-unset -no-empty -i "${input_file}" -o "${output_file}" || {
        printf 'An error happened during processing of %s to %s\n\n' "${input_file}" "${output_file}" >&2
        exit 1
    }
}

process_template '/homelab/web.yml' '/homelab/tmpfs/web.yml'
process_template '/homelab/prometheus.yml' '/homelab/tmpfs/prometheus.yml'

promtool check web-config '/homelab/tmpfs/web.yml'
promtool check config '/homelab/tmpfs/prometheus.yml'

exec prometheus \
    --config.file='/homelab/tmpfs/prometheus.yml' \
    --storage.tsdb.path='/prometheus' \
    --storage.tsdb.retention.time=30d \
    --web.config.file='/homelab/tmpfs/web.yml'
