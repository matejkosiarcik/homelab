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

output='app-secrets'
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
        # A simple password for debugging
        printf 'Password123.' >"$output_file"
    else
        # shellcheck disable=SC2086
        python3 "$helper_script_dir/password.py" --output "$output_file" $extra_flags
    fi
}

user_logfile="$tmpdir/user-logs.txt"

create_http_proxy_auth_users() {
    create_http_auth_user proxy-status
}

create_http_auth_user() {
    # $1 - user
    create_password "$tmpdir/http-$1-password.txt" --only-alphanumeric
    printf '%s:%s\n' "$1" "$(cat "$tmpdir/http-$1-password.txt")" >>"$output/htpasswd-users.txt"
    chronic htpasswd -c -B -i "$output/http-user--$1.htpasswd" "$1" <"$tmpdir/http-$1-password.txt"
}

prepare_healthcheck_url() {
    # $1 - file
    prepare_empty_env HOMELAB_HEALTHCHECK_URL "$1"
}

prepare_empty_env() {
    # $1 - env name
    # $2 - file
    printf '%s=\n' "$1" >>"$2"
    printf 'You must configure "%s" in %s\n' "$1" "$(basename "$2")" >>"$user_logfile"
}

case "$current_dir" in
*docker-cache-proxy*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/app-http-secret.txt" --only-alphanumeric

    # App
    printf 'REGISTRY_HTTP_SECRET=%s\n' "$(cat "$tmpdir/app-http-secret.txt")" >>"$output/docker-registry.env"
    prepare_empty_env REGISTRY_PROXY_REMOTEURL "$output/docker-registry.env"
    prepare_empty_env REGISTRY_PROXY_USERNAME "$output/docker-registry.env"
    prepare_empty_env REGISTRY_PROXY_PASSWORD "$output/docker-registry.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*healthchecks*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/healthchecks-secret-key.txt" --only-alphanumeric

    # App
    printf 'SECRET_KEY=%s\n' "$(cat "$tmpdir/healthchecks-secret-key.txt")" >>"$output/healthchecks.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*home-assistant*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/app-http-secret.txt" --only-alphanumeric

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*homer*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*lamp-controller*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*omada-controller*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"
    prepare_healthcheck_url "$output/web-backup.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    printf 'admin' >"$tmpdir/admin-username.txt"

    # Backups
    printf 'HOMELAB_APP_USERNAME=%s\n' "$(cat "$tmpdir/admin-username.txt")" >>"$output/web-backup.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-backup.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*pihole*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"
    prepare_healthcheck_url "$output/web-backup.env"
    prepare_healthcheck_url "$output/web-custom-setup.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"

    # App
    printf '%s' "$(cat "$tmpdir/admin-password.txt")" >>"$output/pihole-password.txt"

    # Backups
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-backup.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-custom-setup.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*smtp4dev*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*speedtest-tracker*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"
    prepare_healthcheck_url "$output/web-admin-setup.env"
    prepare_healthcheck_url "$output/web-export.env"
    npm --prefix "$helper_script_dir/playwright" run --silent run:speedtest-tracker-app-key -- --output "$tmpdir/app-key.txt"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    if [ "$dev_mode" = '1' ]; then
        printf 'admin@localhost' >"$tmpdir/admin-username.txt"
    else
        prepare_empty_env ADMIN_EMAIL "$output/speedtest-tracker.env"
        prepare_empty_env HOMELAB_APP_USERNAME "$output/web-admin-setup.env"
        prepare_empty_env HOMELAB_APP_USERNAME "$output/web-export.env"
        printf '' >"$tmpdir/admin-username.txt"
    fi

    # App
    printf 'APP_KEY=%s\n' "$(cat "$tmpdir/app-key.txt")" >>"$output/speedtest-tracker.env"
    # TODO: Save username/password to `speedtest-tracker.env` after https://github.com/alexjustesen/speedtest-tracker/issues/1597
    printf '# ADMIN_EMAIL=%s\n' "$(cat "$tmpdir/admin-username.txt")" >>"$output/speedtest-tracker.env"
    printf '# ADMIN_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/speedtest-tracker.env"

    # Automation
    printf 'HOMELAB_APP_USERNAME=%s\n' "$(cat "$tmpdir/admin-username.txt")" >>"$output/web-admin-setup.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-admin-setup.env"
    printf 'HOMELAB_APP_USERNAME=%s\n' "$(cat "$tmpdir/admin-username.txt")" >>"$output/web-export.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-export.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*unifi-controller*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"
    prepare_healthcheck_url "$output/web-backup.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    printf 'admin' >"$tmpdir/admin-username.txt"
    create_password "$tmpdir/database-password.txt"

    # Database
    printf '%s' "$(cat "$tmpdir/database-password.txt")" >>"$output/database-password.txt"

    # Backups
    printf 'HOMELAB_APP_USERNAME=%s\n' "$(cat "$tmpdir/admin-username.txt")" >>"$output/web-backup.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-backup.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*uptime-kuma*)
    create_http_proxy_auth_users
    prepare_healthcheck_url "$output/certificate-manager.env"
    prepare_healthcheck_url "$output/web-admin-setup.env"
    prepare_healthcheck_url "$output/web-backup.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    printf 'admin' >"$tmpdir/admin-username.txt"

    # Automation
    printf 'HOMELAB_APP_USERNAME=%s\n' "$(cat "$tmpdir/admin-username.txt")" >>"$output/web-admin-setup.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-admin-setup.env"
    printf 'HOMELAB_APP_USERNAME=%s\n' "$(cat "$tmpdir/admin-username.txt")" >>"$output/web-backup.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-backup.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*)
    printf 'Unknown app directory name: %s\n' "$current_dir" >&2
    exit 1
    ;;
esac

# Cleanup
rm -rf "$tmpdir"
