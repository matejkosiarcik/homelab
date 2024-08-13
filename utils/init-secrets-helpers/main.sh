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

current_dir="$(basename "$PWD")"
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

case "$current_dir" in
healthchecks)
    # Precreate passwords
    create_password "$tmpdir/database-password.txt"
    create_password "$tmpdir/app-secret-key.txt" --only-alphanumeric
    create_password "$tmpdir/http-proxy-status-password.txt" --only-alphanumeric

    # App
    printf 'SECRET_KEY=%s\n' "$(cat "$tmpdir/app-secret-key.txt")" >>"$output/app.env"
    printf 'DB_PASSWORD=%s\n' "$(cat "$tmpdir/database-password.txt")" >>"$output/app.env"

    # Database
    printf '%s' "$(cat "$tmpdir/database-password.txt")" >>"$output/database-password.txt"

    # Backups
    printf 'PGPASSWORD=%s\n' "$(cat "$tmpdir/database-password.txt")" >>"$output/database-backup.env"
    printf 'HOMELAB_HEALTHCHECK_URL=\n' >>"$output/database-backup.env"

    # HTTP proxy
    printf 'status - %s\n' "$(cat "$tmpdir/http-proxy-status-password.txt")" >>"$output/http-proxy-users.txt"
    chronic htpasswd -c -B -i "$output/http-proxy-status.htpasswd" status <"$tmpdir/http-proxy-status-password.txt"

    # Log results
    printf 'Not all secrets setup\n' >&2
    printf 'You must configure "HOMELAB_HEALTHCHECK_URL" in database-backup.env\n' >&2
    ;;
homer)
    # Precreate passwords
    create_password "$tmpdir/http-proxy-status-password.txt" --only-alphanumeric

    # HTTP proxy
    printf 'status - %s\n' "$(cat "$tmpdir/http-proxy-status-password.txt")" >>"$output/http-proxy-users.txt"
    chronic htpasswd -c -B -i "$output/http-proxy-status.htpasswd" status <"$tmpdir/http-proxy-status-password.txt"

    # Log results
    printf 'Not all secrets setup\n' >&2
    printf 'You must configure "HOMELAB_HEALTHCHECK_URL" in <<TBD>>\n' >&2
    ;;
lamp-controller)
    # Precreate passwords
    create_password "$tmpdir/http-proxy-status-password.txt" --only-alphanumeric

    # HTTP proxy
    printf 'status - %s\n' "$(cat "$tmpdir/http-proxy-status-password.txt")" >>"$output/http-proxy-users.txt"
    chronic htpasswd -c -B -i "$output/http-proxy-status.htpasswd" status <"$tmpdir/http-proxy-status-password.txt"

    # Log results
    printf 'Not all secrets setup\n' >&2
    printf 'You must configure "HOMELAB_HEALTHCHECK_URL" in <<TBD>>\n' >&2
    ;;
smtp4dev)
    # Precreate passwords
    create_password "$tmpdir/http-proxy-status-password.txt" --only-alphanumeric

    # HTTP proxy
    printf 'status - %s\n' "$(cat "$tmpdir/http-proxy-status-password.txt")" >>"$output/http-proxy-users.txt"
    chronic htpasswd -c -B -i "$output/http-proxy-status.htpasswd" status <"$tmpdir/http-proxy-status-password.txt"

    # Log results
    printf 'Not all secrets setup\n' >&2
    printf 'You must configure "HOMELAB_HEALTHCHECK_URL" in <<TBD>>\n' >&2
    ;;
pihole | pihole-main)
    # Precreate passwords
    create_password "$tmpdir/http-proxy-status-password.txt" --only-alphanumeric
    create_password "$tmpdir/app-password.txt"

    # Database
    printf '%s' "$(cat "$tmpdir/app-password.txt")" >>"$output/webpassword.txt"

    # Backups
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/app-password.txt")" >>"$output/webui-backup.env"
    printf 'HOMELAB_HEALTHCHECK_URL=\n' >>"$output/webui-backup.env"

    # HTTP proxy
    printf 'status - %s\n' "$(cat "$tmpdir/http-proxy-status-password.txt")" >>"$output/http-proxy-users.txt"
    chronic htpasswd -c -B -i "$output/http-proxy-status.htpasswd" status <"$tmpdir/http-proxy-status-password.txt"

    # Log results
    printf 'Not all secrets setup\n' >&2
    printf 'You must configure "HOMELAB_HEALTHCHECK_URL" in webui-backup.env\n' >&2
    ;;
*)
    printf 'Unknown app directory "%s"\n' "$current_dir" >&2
    exit 1
    ;;
esac

# Cleanup
rm -rf "$tmpdir"
