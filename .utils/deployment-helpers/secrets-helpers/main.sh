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

online_mode='online'
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
    --online)
        online_mode='online'
        shift
        ;;
    --offline)
        online_mode='offline'
        shift
        ;;
    *)
        printf 'Unknown argument %s\n' "$1"
        exit 1
        ;;
    esac
done

if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
    if [ "${BW_SESSION-}" = '' ]; then
        echo 'You must set BW_SESSION env variable before calling this script.' >&2
        exit 1
    fi
fi

if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
    bw sync                  # Sync latest changes
    bw list items >/dev/null # Verify we can access Vaultwarden
fi

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

app_dir="$PWD"
full_app_name="$(basename "$app_dir")"
server_name="$(basename "$(realpath "$(dirname "$(dirname "$app_dir")")")")"
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

load_username() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    if [ "$mode" = 'prod' ]; then
        bw list items --search "homelab--$1--$2--$3" | jq -er ".[] | select(.name == \"homelab--$1--$2--$3\").login.username"
    else
        printf '%s\n' "$3"
    fi
}

load_password() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    if [ "$mode" = 'prod' ]; then
        bw list items --search "homelab--$1--$2--$3" | jq -er ".[] | select(.name == \"homelab--$1--$2--$3\").login.password"
    else
        printf 'Password123.\n'
    fi
}

load_token() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
        bw list items --search "homelab--$1--$2--$3" | jq -er ".[] | select(.name == \"homelab--$1--$2--$3\").login.password"
    else
        printf '\n'
    fi
}

load_notes() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
        bw list items --search "homelab--$1--$2--$3" | jq -er ".[] | select(.name == \"homelab--$1--$2--$3\").notes"
    else
        printf '\n'
    fi
}

load_healthcheck_id() {
    # $1 - app name
    # $2 - container name

    if [ "$mode" = 'prod' ]; then
        bw list items --search "homelab--$1--$2--healthchecks-id" | jq -er ".[] | select(.name == \"homelab--$1--$2--healthchecks-id\").login.password"
    else
        printf '\n'
    fi
}

write_healthcheck_url() {
    # $1 - container name
    # $2 - healthchecks id

    if [ "$2" = '' ]; then
        healthcheck_url=''
    else
        healthcheck_url="https://healthchecks.home/ping/$2"
    fi
    printf 'HOMELAB_HEALTHCHECK_URL=%s\n' "$healthcheck_url" >>"$output/$1.env"
}

write_http_auth_user() {
    # $1 - username
    # $2 - password
    printf '%s' "$2" | chronic htpasswd -c -B -i "$output/http-user--$1.htpasswd" "$1"
}

hash_password_bcrypt() {
    # $1 - password
    # returns password on stdout
    printf '%s' "$1" | chronic htpasswd -c -B -i "$tmpdir/bcrypt-password-placeholder.txt" 'placeholder'
    sed -E 's~^placeholder:~~' <"$tmpdir/bcrypt-password-placeholder.txt"
    rm -f "$tmpdir/bcrypt-password-placeholder.txt"
}

case "$full_app_name" in
*actualbudget*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*changedetection*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*docker*-proxy*)
    # App
    http_secret="$(load_password "$full_app_name" app http-secret)"
    printf 'REGISTRY_HTTP_SECRET=%s\n' "$http_secret" >>"$output/docker-registry.env"
    printf 'REGISTRY_PROXY_USERNAME=\n' >>"$output/docker-registry.env"
    printf 'REGISTRY_PROXY_PASSWORD=\n' >>"$output/docker-registry.env"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*dozzle-agent*)
    # App
    if [ "$mode" = 'prod' ]; then
        app_key="$(load_notes dozzle app key)"
        printf '%s\n' "$app_key" >"$output/dozzle-key.pem"
        app_cert="$(load_notes dozzle app cert)"
        printf '%s\n' "$app_cert" >"$output/dozzle-cert.pem"
    else
        sh "$helper_script_dir/dozzle/main.sh" "$output"
    fi
    ;;
*dozzle-server*)
    # App
    admin_password="$(load_password dozzle app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    hash_password_bcrypt "$admin_password" >"$tmpdir/admin-password-bcrypt.txt"
    printf 'users:\n admin:\n  email: admin@%s\n  name: admin\n  password: %s\n' "$DOCKER_COMPOSE_NETWORK_DOMAIN" "$(cat "$tmpdir/admin-password-bcrypt.txt")" |
        sed -E 's~^( +)~\1\1\1\1~' >"$output/dozzle-users.yml"
    if [ "$mode" = 'prod' ]; then
        app_key="$(load_notes dozzle app key)"
        printf '%s\n' "$app_key" >"$output/dozzle-key.pem"
        app_cert="$(load_notes dozzle app cert)"
        printf '%s\n' "$app_cert" >"$output/dozzle-cert.pem"
    else
        sh "$helper_script_dir/dozzle/main.sh" "$output"
    fi

    # HTTP Proxy
    proxy_status_password="$(load_password dozzle http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id dozzle certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*gatus*)
    # App
    printf 'GATUS_1_PROMETHEUS_TOKEN=%s\n' "$(load_token gatus app prometheus)" >>"$output/gatus.env"
    printf 'GATUS_2_PROMETHEUS_TOKEN=%s\n' "$(load_token gatus-2 app prometheus)" >>"$output/gatus.env"
    printf 'GLANCES_ODROID_H3_PASSWORD=%s\n' "$(load_token glances--odroid-h3 app admin)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_3B_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-3b app admin)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-2g app admin)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-4g app admin)" >>"$output/gatus.env"
    printf 'HOMEASSISTANT_PROMETHEUS_TOKEN=%s\n' "$(load_token homeassistant app prometheus-api-key)" >>"$output/gatus.env"
    printf 'MINIO_PROMETHEUS_TOKEN=%s\n' "$(load_token minio app prometheus-token)" >>"$output/gatus.env"
    printf 'NTFY_TOKEN=%s\n' "$(load_token ntfy app publisher-token)" >>"$output/gatus.env"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"
    app_prometheus_password="$(load_password "$full_app_name" app prometheus)"
    write_http_auth_user prometheus "$app_prometheus_password"
    printf 'prometheus,%s\n' "$app_prometheus_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*glances*)
    # App
    admin_password="$(load_password "$full_app_name--$server_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    sh "$helper_script_dir/glances/main.sh" "$admin_password" "$output/glances-password.txt"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name--$server_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name--$server_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*healthchecks*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    if [ "$mode" = 'dev' ]; then
        admin_email='admin@healthchecks.localhost'
    else
        admin_email="admin@$DOCKER_COMPOSE_NETWORK_DOMAIN"
    fi
    printf '%s,%s\n' "$admin_email" "$admin_password" >>"$output/all-credentials.csv"
    ntfy_token="$(load_password "$full_app_name" app secret-key)"
    printf 'SECRET_KEY=%s\n' "$ntfy_token" >>"$output/healthchecks.env"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*homeassistant*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*homepage*)
    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"

    # App
    changedetection_apikey="$(load_token changedetection app api-key)"
    printf 'HOMEPAGE_VAR_CHANGEDETECTION_APIKEY=%s\n' "$changedetection_apikey" >>"$output/homepage.env"
    healthchecks_apikey="$(load_token healthchecks app api-key)"
    printf 'HOMEPAGE_VAR_HEALTHCHECKS_APIKEY=%s\n' "$healthchecks_apikey" >>"$output/homepage.env"
    homeassistant_apikey="$(load_token homeassistant app homepage-api-key)"
    printf 'HOMEPAGE_VAR_HOMEASSISTANT_APIKEY=%s\n' "$homeassistant_apikey" >>"$output/homepage.env"
    jellyfin_apikey="$(load_token jellyfin app homepage-api-key)"
    printf 'HOMEPAGE_VAR_JELLYFIN_PASSWORD=%s\n' "$jellyfin_apikey" >>"$output/homepage.env"
    # TODO: Enable NetAlertX integration
    # netalertx_apikey="$(load_password netalertx app homepage-api-key)"
    # printf 'HOMEPAGE_VAR_NETALERTX_APIKEY=%s\n' "$netalertx_apikey" "$output/homepage.env"
    omadacontroller_password="$(load_password omada-controller app homepage)"
    printf 'HOMEPAGE_VAR_OMADA_CONTROLLER_PASSWORD=%s\n' "$omadacontroller_password" >>"$output/homepage.env"
    pihole1p_apikey="$(load_token pihole-1-primary app api-key)"
    printf 'HOMEPAGE_VAR_PIHOLE_1_PRIMARY_APIKEY=%s\n' "$pihole1p_apikey" >>"$output/homepage.env"
    pihole1s_apikey="$(load_token pihole-1-secondary app api-key)"
    printf 'HOMEPAGE_VAR_PIHOLE_1_SECONDARY_APIKEY=%s\n' "$pihole1s_apikey" >>"$output/homepage.env"
    pihole2p_apikey="$(load_token pihole-2-primary app api-key)"
    printf 'HOMEPAGE_VAR_PIHOLE_2_PRIMARY_APIKEY=%s\n' "$pihole2p_apikey" >>"$output/homepage.env"
    pihole2s_apikey="$(load_token pihole-2-secondary app api-key)"
    printf 'HOMEPAGE_VAR_PIHOLE_2_SECONDARY_APIKEY=%s\n' "$pihole2s_apikey" >>"$output/homepage.env"
    unificontroller_password="$(load_password unifi-controller app homepage)"
    printf 'HOMEPAGE_VAR_UNIFI_CONTROLLER_PASSWORD=%s\n' "$unificontroller_password" >>"$output/homepage.env"
    # TODO: Enable Vikunja integration
    # vikunja_apikey="$(load_password vikunja app homepage-api-key)"
    # printf 'HOMEPAGE_VAR_VIKUNJA_APIKEY=%s\n' "$vikunja_apikey" "$output/homepage.env"
    ;;
*jellyfin*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*minio*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    user_password="$(load_password "$full_app_name" app user)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"
    printf 'MINIO_ROOT_USER=admin\n' >>"$output/minio.env"
    printf 'MINIO_ROOT_PASSWORD=%s\n' "$admin_password" >>"$output/minio.env"

    # Setup
    printf 'HOMELAB_ADMIN_USERNAME=admin\n' >>"$output/minio-setup.env"
    printf 'HOMELAB_ADMIN_PASSWORD=%s\n' "$admin_password" >>"$output/minio-setup.env"
    printf 'HOMELAB_USER_USERNAME=user\n' >>"$output/minio-setup.env"
    printf 'HOMELAB_USER_PASSWORD=%s\n' "$user_password" >>"$output/minio-setup.env"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*motioneye*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    user_password="$(load_password "$full_app_name" app user)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*ntfy*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    user_password="$(load_password "$full_app_name" app user)"
    publisher_password="$(load_password "$full_app_name" app publisher)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"
    printf 'publisher,%s\n' "$publisher_password" >>"$output/all-credentials.csv"
    printf 'NTFY_PASSWORD_ADMIN=%s\n' "$admin_password" >>"$output/ntfy.env"
    printf 'NTFY_PASSWORD_USER=%s\n' "$user_password" >>"$output/ntfy.env"
    printf 'NTFY_PASSWORD_PUBLISHER=%s\n' "$publisher_password" >>"$output/ntfy.env"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*omada-controller*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    viewer_password="$(load_password "$full_app_name" app viewer)"
    device_password="$(load_password "$full_app_name" app device)"
    homepage_password="$(load_password "$full_app_name" app homepage)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'viewer,%s\n' "$viewer_password" >>"$output/all-credentials.csv"
    printf 'device,%s\n' "$device_password" >>"$output/all-credentials.csv"
    printf 'homepage,%s\n' "$homepage_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*openspeedtest*)
    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*pihole*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf '%s\n' "$admin_password" >>"$output/pihole-password.txt"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*renovatebot*)
    # App
    healthcheck_id="$(load_healthcheck_id "$full_app_name" app)"
    write_healthcheck_url renovatebot "$healthcheck_id"
    renovate_token="$(load_token "$full_app_name" app renovate-token)" # PAT specific for each git host
    github_token="$(load_token "$full_app_name" app github-token)"     # GitHub PAT (even if using other git hosts)
    printf 'RENOVATE_TOKEN=%s\n' "$renovate_token" >>"$output/renovatebot.env"
    printf 'GITHUB_COM_TOKEN=%s\n' "$github_token" >>"$output/renovatebot.env"
    ;;
*smb*)
    # App
    smb_password="$(load_password "$full_app_name" app user)"
    printf 'smb,%s\n' "$smb_password" >>"$output/all-credentials.csv"
    printf 'SAMBA_USERNAME=user\n' >>"$output/samba.env"
    printf 'SAMBA_PASSWORD=%s\n' "$smb_password" >>"$output/samba.env"
    ;;
*smtp4dev*)
    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*speedtest-tracker*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    if [ "$mode" = 'dev' ]; then
        admin_email='admin@speedtest-tracker.localhost'
        sh "$helper_script_dir/speedtest-tracker/main.sh" "$tmpdir/speedtest-tracker-app-key.txt"
        app_key="$(cat "$tmpdir/speedtest-tracker-app-key.txt")"
    else
        admin_email="admin@$DOCKER_COMPOSE_NETWORK_DOMAIN"
        app_key="$(load_token "$full_app_name" app app-key)"
    fi
    printf '%s,%s\n' "$admin_email" "$admin_password" >>"$output/all-credentials.csv"
    printf 'APP_KEY=%s\n' "$app_key" >>"$output/speedtest-tracker.env"
    printf 'ADMIN_NAME=Admin\n' >>"$output/speedtest-tracker.env"
    printf 'ADMIN_EMAIL=%s\n' "$admin_email" >>"$output/speedtest-tracker.env"
    printf 'ADMIN_PASSWORD=%s\n' "$admin_password" >>"$output/speedtest-tracker.env"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*tvheadend*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    user_password="$(load_password "$full_app_name" app user)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*unifi-controller*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    viewer_password="$(load_password "$full_app_name" app viwer)"
    homepage_password="$(load_password "$full_app_name" app homepage)"
    mongodb_password="$(load_password "$full_app_name" mongodb admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'viewer,%s\n' "$viewer_password" >>"$output/all-credentials.csv"
    printf 'homepage,%s\n' "$homepage_password" >>"$output/all-credentials.csv"
    printf 'mongodb,%s\n' "$mongodb_password" >>"$output/all-credentials.csv"

    # Database
    printf 'MONGO_PASSWORD=%s\n' "$mongodb_password" >>"$output/mongodb.env"
    printf '%s' "$mongodb_password" >>"$output/mongodb-password.txt"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*vaultwarden*)
    # App
    superadmin_password="$(load_password "$full_app_name" app superadmin)"
    superadmin_password_hashed="$(printf '%s' "$superadmin_password" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4 | sed 's~\$~$$~g')"
    admin_password="$(load_password "$full_app_name" app admin)"
    if [ "$mode" = 'dev' ]; then
        admin_email='admin@vaultwarden.localhost'
    else
        admin_email="admin@$DOCKER_COMPOSE_NETWORK_DOMAIN"
    fi
    homelab_password="$(load_password "$full_app_name" app homelab)"
    if [ "$mode" = 'dev' ]; then
        homelab_email='homelab@vaultwarden.localhost'
    else
        homelab_email="homelab@$DOCKER_COMPOSE_NETWORK_DOMAIN"
    fi
    printf 'ADMIN_TOKEN=%s\n' "$superadmin_password_hashed" >>"$output/vaultwarden.env"
    printf 'superadmin,%s\n' "$superadmin_password" >>"$output/all-credentials.csv"
    printf '%s,%s\n' "$admin_email" "$admin_password" >>"$output/all-credentials.csv"
    printf '%s,%s\n' "$homelab_email" "$homelab_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    proxy_status_password="$(load_password "$full_app_name" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"

    # Certificate Manager
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-manager)"
    write_healthcheck_url certificate-manager "$healthcheck_id"
    ;;
*)
    printf 'Unknown app directory name: %s\n' "$app_dir" >&2
    exit 1
    ;;
esac

# Cleanup
rm -rf "$tmpdir"
