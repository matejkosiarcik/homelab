#!/bin/sh
set -euf

helper_script_dir="$(cd "$(dirname "$0")" >/dev/null && pwd)"

LANG=en_US.UTF-8
export LANG
LANGUAGE=en_US.UTF-8
export LANGUAGE
LC_ALL=en_US.UTF-8
export LC_ALL
LC_CTYPE=en_US.UTF-8
export LC_CTYPE

dev_mode='0'
force_mode='0'
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d | --dev)
        dev_mode='1'
        shift
        ;;
    -f | --force)
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
current_dir="$(basename "$PWD")"

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

case "$current_dir" in
homer)
    # HTTP proxy
    create_password "$tmpdir/apache-status-password.txt" --only-alphanumeric
    printf 'status:%s\n' "$(cat "$tmpdir/apache-status-password.txt")" >>"$output/apache-users.txt"
    chronic htpasswd -c -B -i "$output/status.htpasswd" status <"$tmpdir/apache-status-password.txt"

    # Log results
    printf 'All secrets setup\n' >&2
    ;;
lamp-controller)
    # HTTP proxy
    create_password "$tmpdir/apache-status-password.txt" --only-alphanumeric
    printf 'status:%s\n' "$(cat "$tmpdir/apache-status-password.txt")" >>"$output/apache-users.txt"
    chronic htpasswd -c -B -i "$output/status.htpasswd" status <"$tmpdir/apache-status-password.txt"

    # Log results
    printf 'All secrets setup\n' >&2
    ;;
pihole | pihole-main)
    # App
    create_password "$output/webpassword.txt"

    # Backups
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$output/webpassword.txt")" >>"$output/webui-backup.env"
    printf 'HOMELAB_HEALTHCHECK_URL=\n' >>"$output/webui-backup.env"

    # HTTP proxy
    create_password "$tmpdir/apache-status-password.txt" --only-alphanumeric
    printf 'status:%s\n' "$(cat "$tmpdir/apache-status-password.txt")" >>"$output/apache-users.txt"
    chronic htpasswd -c -B -i "$output/status.htpasswd" status <"$tmpdir/apache-status-password.txt"

    # Log results
    printf 'Not all secrets setup\n' >&2
    printf 'You must configure custom "HOMELAB_HEALTHCHECK_URL"\n' >&2
    ;;
*)
    printf 'Unknown app directory "%s"\n' "$current_dir" >&2
    exit 1
    ;;
esac

# Cleanup
rm -rf "$tmpdir"
