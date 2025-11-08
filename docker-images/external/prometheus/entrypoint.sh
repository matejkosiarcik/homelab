#!/bin/sh
set -euf

process_template() {
    input_file="$1"
    output_file="$2"

    if [ ! -f "$input_file" ]; then
        printf "Error: Template file %s not found\n" "$input_file" >&2
        exit 1
    fi

    tmpdir="$(mktemp -d)"
    tmpfile="$tmpdir/file.txt"
    linefile="$tmpdir/line.txt"

    cat "$input_file" | sed -E 's~^ ~_~g' | while read -r line; do
        variables="$(printf '%s' "$line" | grep -E -o '\$\{[^}]*\}' 2>/dev/null | sed -E 's~^\$\{([^}]*)\}~\1~' || true)"

        printf '%s\n' "$line" >"$linefile"

        printf '%s\n' "$variables" | while read -r var; do
            if [ "$var" = '' ]; then
                continue;
            fi

            # Read variable value
            value="$(printenv "$var")" || {
                printf "Error: Environment variable %s not set\n" "$var" >&2
                rm -rf "$tmpdir"
                exit 1
            }

            # Decode (base64) variable value if necessary
            if printf '%s' "$var" | grep -E '_ENCRYPTED$' >/dev/null 2>&1; then
                value="$(printf '%s' "$value" | base64 -d 2>/dev/null)" || {
                    printf "Error: Failed to base64 decode variable %s\n" "$var" >&2
                    rm -rf "$tmpdir"
                    exit 1
                }
            fi

            line="$(cat "$linefile" | sed "s~\${$var}~$value~g")"
            printf '%s\n' "$line" >"$linefile"
        done

        cat "$linefile" >>"$tmpfile"
    done

    cat "$tmpfile" | sed -E 's~^_~ ~g' >"$output_file"
}

process_template /homelab/web.yml /homelab/config/web.yml
process_template /homelab/prometheus.yml /homelab/config/prometheus.yml

if [ "$(wc -l </homelab/config/web.yml)" -eq 0 ]; then
    printf "Error: File /homelab/config/web.yml is empty" >&2
    exit 1
fi
if [ "$(wc -l </homelab/config/prometheus.yml)" -eq 0 ]; then
    printf "Error: File /homelab/config/prometheus.yml is empty" >&2
    exit 1
fi

promtool check web-config /homelab/config/web.yml
promtool check config /homelab/config/prometheus.yml

prometheus \
    --config.file=/homelab/config/prometheus.yml \
    --storage.tsdb.path=/prometheus \
    --storage.tsdb.retention.time=30d \
    --web.config.file=/homelab/config/web.yml
