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

mode=''
force_mode='0'
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d | --dev)
        mode='dev'
        shift
        ;;
    -f | --force)
        force_mode='1'
        shift
        ;;
    -p | --prod)
        mode='prod'
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
printf 'user,password\n' >"$output/all-credentials.csv"

current_dir="$(basename "$PWD")"
tmpdir="$(mktemp -d)"

# Load custom docker-compose overrides if available
if [ -f "$PWD/config/docker-compose.env" ]; then
    # shellcheck source=/dev/null
    . "$PWD/config/docker-compose.env"
fi
if [ -f "$PWD/config/docker-compose-$mode.env" ]; then
    # shellcheck source=/dev/null
    . "$PWD/config/docker-compose-$mode.env"
fi

create_password() {
    output_file="$1"
    extra_flags=''
    if [ "$#" -ge 2 ]; then
        extra_flags="$2"
    fi

    if [ "$mode" = 'dev' ]; then
        # A simple password for debugging
        printf 'Password123.' >"$output_file"
    else
        # shellcheck disable=SC2086
        python3 "$helper_script_dir/password.py" --output "$output_file" $extra_flags
    fi
}

create_secret() {
    output_file="$1"
    length="$2"

    # shellcheck disable=SC2086
    python3 "$helper_script_dir/generic-secret.py" --output "$output_file" --length "$length"
}

user_logfile="$tmpdir/user-logs.txt"
touch "$user_logfile"

create_http_auth_user() {
    # $1 - user
    create_password "$tmpdir/http-$1-password.txt" --only-alphanumeric
    printf '%s,%s\n' "$1" "$(cat "$tmpdir/http-$1-password.txt")" >>"$output/all-credentials.csv"
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
    printf 'You must configure env "%s" in %s\n' "$1" "$(basename "$2")" >>"$user_logfile"
}

prepare_empty_password() {
    # $1 - username
    printf '%s,\n' "$1" >>"$output/all-credentials.csv"
    printf 'You must configure password for "%s"\n' "$1" >>"$user_logfile"
}

case "$current_dir" in
*actualbudget*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*changedetection*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*docker*-proxy*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/docker-registry-http-secret.txt" --only-alphanumeric

    # App
    printf 'REGISTRY_HTTP_SECRET=%s\n' "$(cat "$tmpdir/docker-registry-http-secret.txt")" >>"$output/docker-registry.env"
    prepare_empty_env REGISTRY_PROXY_USERNAME "$output/docker-registry.env"
    prepare_empty_env REGISTRY_PROXY_PASSWORD "$output/docker-registry.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*gatus*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # App
    prepare_empty_env NTFY_TOKEN "$output/gatus.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*healthchecks*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/healthchecks-secret-key.txt" --only-alphanumeric
    printf 'admin@%s.home' "$DOCKER_COMPOSE_APP_NAME" >"$tmpdir/admin-username.txt"
    create_password "$tmpdir/admin-password.txt"

    # App
    printf 'SECRET_KEY=%s\n' "$(cat "$tmpdir/healthchecks-secret-key.txt")" >>"$output/healthchecks.env"

    # Misc
    printf '%s,%s\n' "$(cat "$tmpdir/admin-username.txt")" "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*homeassistant*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"
    prepare_healthcheck_url "$output/web-backup.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"

    # Web backup
    printf 'HOMELAB_APP_USERNAME=admin\n' >>"$output/web-backup.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-backup.env"

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"
    prepare_empty_password matej
    prepare_empty_password monika

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*homepage*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Prepare API keys
    prepare_empty_env HOMEPAGE_VAR_CHANGEDETECTION_APIKEY "$output/homepage.env"
    prepare_empty_env HOMEPAGE_VAR_HEALTHCHECKS_APIKEY "$output/homepage.env"
    prepare_empty_env HOMEPAGE_VAR_PIHOLE_1_APIKEY "$output/homepage.env"
    prepare_empty_env HOMEPAGE_VAR_PIHOLE_2_APIKEY "$output/homepage.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*jellyfin*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"
    prepare_empty_password matej
    prepare_empty_password monika

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*lamp-*wrapper*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*minio*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    create_password "$tmpdir/user-password.txt"

    # App
    printf 'MINIO_ROOT_USER=admin\n' >>"$output/minio.env"
    printf 'MINIO_ROOT_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/minio.env"

    # Setup
    printf 'HOMELAB_ADMIN_USERNAME=admin\n' >>"$output/minio-setup.env"
    printf 'HOMELAB_ADMIN_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/minio-setup.env"
    printf 'HOMELAB_USER_USERNAME=user\n' >>"$output/minio-setup.env"
    printf 'HOMELAB_USER_PASSWORD=%s\n' "$(cat "$tmpdir/user-password.txt")" >>"$output/minio-setup.env"

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$(cat "$tmpdir/user-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*ntfy*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    create_password "$tmpdir/user-password.txt"
    create_password "$tmpdir/publisher-password.txt" --only-alphanumeric

    # App
    printf 'NTFY_PASSWORD_ADMIN=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/ntfy.env"
    printf 'NTFY_PASSWORD_USER=%s\n' "$(cat "$tmpdir/user-password.txt")" >>"$output/ntfy.env"
    printf 'NTFY_PASSWORD_PUBLISHER=%s\n' "$(cat "$tmpdir/publisher-password.txt")" >>"$output/ntfy.env"

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$(cat "$tmpdir/user-password.txt")" >>"$output/all-credentials.csv"
    printf 'publisher,%s\n' "$(cat "$tmpdir/publisher-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*omada-controller*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"
    prepare_healthcheck_url "$output/web-backup.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    sed 's~?~#~g' <"$tmpdir/admin-password.txt" | sponge "$tmpdir/admin-password.txt"
    create_password "$tmpdir/device-password.txt"
    sed 's~?~#~g' <"$tmpdir/device-password.txt" | sponge "$tmpdir/device-password.txt"

    # Web backup
    printf 'HOMELAB_APP_USERNAME=admin\n' >>"$output/web-backup.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-backup.env"

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"
    printf 'device,%s\n' "$(cat "$tmpdir/device-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*openspeedtest*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*pihole*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"

    # App
    printf '%s' "$(cat "$tmpdir/admin-password.txt")" >>"$output/pihole-password.txt"

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*smb*)
    create_password "$tmpdir/smb-password.txt"
    printf 'smb' >"$tmpdir/smb-username.txt"

    # Samba
    printf 'SAMBA_PASSWORD=%s\n' "$(cat "$tmpdir/smb-password.txt")" >>"$output/samba.env"
    printf 'SAMBA_USERNAME=%s\n' "$(cat "$tmpdir/smb-username.txt")" >>"$output/samba.env"

    # Misc
    printf '%s,%s\n' "$(cat "$tmpdir/smb-username.txt")" "$(cat "$tmpdir/smb-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'All secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*smtp4dev*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*speedtest-tracker*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"
    npm --prefix "$helper_script_dir/playwright" run --silent run:speedtest-tracker-app-key -- --output "$tmpdir/speedtest-tracker-app-key.txt"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    if [ "$mode" = 'dev' ]; then
        printf 'admin@localhost' >"$tmpdir/admin-username.txt"
    else
        printf 'admin@%s.home' "$DOCKER_COMPOSE_APP_NAME" >"$tmpdir/admin-username.txt"
    fi

    # App
    printf 'APP_KEY=%s\n' "$(cat "$tmpdir/speedtest-tracker-app-key.txt")" >>"$output/speedtest-tracker.env"
    # TODO: Save username/password to `speedtest-tracker.env` after https://github.com/alexjustesen/speedtest-tracker/issues/1597
    printf '# ADMIN_EMAIL=%s\n' "$(cat "$tmpdir/admin-username.txt")" >>"$output/speedtest-tracker.env"
    printf '# ADMIN_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/speedtest-tracker.env"

    # Misc
    printf '%s,%s\n' "$(cat "$tmpdir/admin-username.txt")" "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*tvheadend*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    create_password "$tmpdir/user-password.txt" --only-alphanumeric

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$(cat "$tmpdir/user-password.txt")" >>"$output/all-credentials.csv"

    # Log results
    printf 'Not all secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*unbound*)
    # Log results
    printf 'All secrets setup\n' >&2
    cat "$user_logfile" >&2
    ;;
*unifi-controller*)
    create_http_auth_user proxy-status
    prepare_healthcheck_url "$output/certificate-manager.env"
    prepare_healthcheck_url "$output/web-backup.env"

    # Precreate passwords
    create_password "$tmpdir/admin-password.txt"
    create_password "$tmpdir/mongodb-password.txt"

    # Database
    printf 'MONGO_PASSWORD=%s\n' "$(cat "$tmpdir/mongodb-password.txt")" >>"$output/mongodb.env"
    printf '%s' "$(cat "$tmpdir/mongodb-password.txt")" >>"$output/mongodb-password.txt"

    # Web backup
    printf 'HOMELAB_APP_USERNAME=admin\n' >>"$output/web-backup.env"
    printf 'HOMELAB_APP_PASSWORD=%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/web-backup.env"

    # Misc
    printf 'admin,%s\n' "$(cat "$tmpdir/admin-password.txt")" >>"$output/all-credentials.csv"
    printf 'mongo,%s\n' "$(cat "$tmpdir/mongodb-password.txt")" >>"$output/all-credentials.csv"

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
