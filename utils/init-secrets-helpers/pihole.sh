#!/bin/sh
set -euf

helper_script_dir="$(cd "$(dirname "$0")" >/dev/null && pwd)"
# shellcheck source=/dev/null
. "$helper_script_dir/.shared/env"

dev_mode='0'
force_mode='0'
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d)
        dev_mode='1'
        shift
        ;;
    -f)
        force_mode='1'
        shift
        ;;
    *)
        printf 'Unknown argument %s\n' "$1"
        exit 1
        ;;
    esac
done

output='private'
if [ -e "$output" ]; then
    if [ "$force_mode" -eq 1 ]; then
        rm -rf "$output"
    else
        printf 'Output directory "%s" already exists.\n' "$output" >&2
        exit 1
    fi
fi
mkdir "$output"

tmpdir="$(mktemp -d)"

create_password() {
    output_file="$1"
    extra_flags=''
    if [ "$#" -ge 2 ]; then
        extra_flags="$2"
    fi

    if [ "$dev_mode" = '1' ]; then
        printf 'Password123.' >"$output_file" # A simple password for debugging
    else
        # shellcheck disable=SC2086
        python3 "$helper_script_dir/.shared/password.py" --output "$output_file" $extra_flags
    fi
}

# App
create_password "$output/webpassword.txt"

# Backups
printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$output/webpassword.txt")" >>"$output/webui-backup.env"

# HTTP proxy
create_password "$tmpdir/apache-status-password.txt" --only-alphanumeric
printf 'status:%s\n' "$(cat "$tmpdir/apache-status-password.txt")" >>"$output/apache-users.txt"
chronic htpasswd -c -B -i "$output/status.htpasswd" status <"$tmpdir/apache-status-password.txt"

# Cleanup
rm -rf "$tmpdir"

# Additional notes
printf 'Not all secrets setup\n' >&2
printf 'You must configure custom "HOMELAB_HEALTHCHECK_URL"\n' >&2
