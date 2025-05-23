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
full_app_name="$(basename "$app_dir" | sed -E 's~^\.~~')"
server_name="$(basename "$(realpath "$(dirname "$(dirname "$app_dir")")")")"
tmpdir="$(mktemp -d)"

# Load custom docker compose overrides if available
if [ -f "$PWD/config/compose.env" ]; then
    # shellcheck source=/dev/null
    . "$PWD/config/compose.env"
fi
if [ -f "$PWD/config/compose-$mode.env" ]; then
    # shellcheck source=/dev/null
    . "$PWD/config/compose-$mode.env"
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

write_default_proxy_users() {
    # $1 - app name
    proxy_status_password="$(load_password "$1" http-proxy status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'PROXY_STATUS_PASSWORD=%s\n' "$proxy_status_password" >>"$output/http-proxy-prometheus-exporter.env"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"
    proxy_prometheus_password="$(load_password "$1" http-proxy prometheus)"
    write_http_auth_user proxy-prometheus "$proxy_prometheus_password"
    printf 'proxy-prometheus,%s\n' "$proxy_prometheus_password" >>"$output/all-credentials.csv"
}

case "$full_app_name" in
*actualbudget*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*changedetection*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*docker-build*)
    # App
    healthcheck_id="$(load_healthcheck_id "$full_app_name" app)"
    write_healthcheck_url app "$healthcheck_id"
    ;;
*docker*-proxy*)
    # App
    http_secret="$(load_password "$full_app_name" app http-secret)"
    printf 'REGISTRY_HTTP_SECRET=%s\n' "$http_secret" >>"$output/docker-registry.env"
    printf 'REGISTRY_PROXY_USERNAME=\n' >>"$output/docker-registry.env"
    printf 'REGISTRY_PROXY_PASSWORD=\n' >>"$output/docker-registry.env"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*dozzle-agent*)
    # App
    if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
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
    if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
        app_key="$(load_notes dozzle app key)"
        printf '%s\n' "$app_key" >"$output/dozzle-key.pem"
        app_cert="$(load_notes dozzle app cert)"
        printf '%s\n' "$app_cert" >"$output/dozzle-cert.pem"
    else
        sh "$helper_script_dir/dozzle/main.sh" "$output"
    fi

    # HTTP Proxy
    write_default_proxy_users dozzle

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id dozzle certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*gatus*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    # Main credentials
    printf 'GATUS_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$admin_password" | base64 | tr -d '\n')" >>"$output/gatus.env"
    printf 'GLANCES_MACBOOK_PRO_2012_PASSWORD=%s\n' "$(load_token glances--macbook-pro-2012 app admin)" >>"$output/gatus.env"
    printf 'GLANCES_ODROID_H3_PASSWORD=%s\n' "$(load_token glances--odroid-h3 app admin)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_3B_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-3b app admin)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-2g app admin)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-4g app admin)" >>"$output/gatus.env"
    printf 'HOMEPAGE_PASSWORD=%s\n' "$(load_token homepage app admin)" >>"$output/gatus.env"
    printf 'NTFY_TOKEN=%s\n' "$(load_token ntfy app publisher-token)" >>"$output/gatus.env"
    # Prometheus credentials
    printf 'GATUS_1_PROMETHEUS_TOKEN=%s\n' "$(load_token gatus-1 app prometheus)" >>"$output/gatus.env"
    printf 'GATUS_2_PROMETHEUS_TOKEN=%s\n' "$(load_token gatus-2 app prometheus)" >>"$output/gatus.env"
    printf 'GLANCES_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--odroid-h3 app prometheus)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-2g app prometheus)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-4g app prometheus)" >>"$output/gatus.env"
    printf 'HOMEASSISTANT_PROMETHEUS_TOKEN=%s\n' "$(load_token homeassistant app prometheus-api-key)" >>"$output/gatus.env"
    printf 'MINIO_PROMETHEUS_TOKEN=%s\n' "$(load_token minio app prometheus-token)" >>"$output/gatus.env"
    printf 'PIHOLE_1_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary app prometheus)" >>"$output/gatus.env"
    printf 'PIHOLE_1_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary app prometheus)" >>"$output/gatus.env"
    printf 'PIHOLE_2_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary app prometheus)" >>"$output/gatus.env"
    printf 'PIHOLE_2_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary app prometheus)" >>"$output/gatus.env"
    printf 'PROMETHEUS_PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus app prometheus)" >>"$output/gatus.env"
    # Proxy prometheus credentials
    printf 'ACTUALBUDGET_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token actualbudget http-proxy prometheus)" >>"$output/gatus.env"
    printf 'ACTUALBUDGET_PUBLIC_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token actualbudget-public http-proxy prometheus)" >>"$output/gatus.env"
    printf 'CHANGEDETECTION_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token changedetection http-proxy prometheus)" >>"$output/gatus.env"
    printf 'DOCKERHUB_CACHE_PROXY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dockerhub-cache-proxy http-proxy prometheus)" >>"$output/gatus.env"
    printf 'DOZZLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dozzle http-proxy prometheus)" >>"$output/gatus.env"
    printf 'GATUS_1_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 http-proxy prometheus)" >>"$output/gatus.env"
    printf 'GATUS_2_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 http-proxy prometheus)" >>"$output/gatus.env"
    printf 'GLANCES_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--macbook-pro-2012 http-proxy prometheus)" >>"$output/gatus.env"
    printf 'GLANCES_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--odroid-h3 http-proxy prometheus)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-2g http-proxy prometheus)" >>"$output/gatus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-4g http-proxy prometheus)" >>"$output/gatus.env"
    printf 'HEALTHCHECKS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token healthchecks http-proxy prometheus)" >>"$output/gatus.env"
    printf 'HOMEASSISTANT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homeassistant http-proxy prometheus)" >>"$output/gatus.env"
    printf 'HOMEPAGE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homepage http-proxy prometheus)" >>"$output/gatus.env"
    printf 'JELLYFIN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token jellyfin http-proxy prometheus)" >>"$output/gatus.env"
    printf 'MINIO_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio http-proxy prometheus)" >>"$output/gatus.env"
    printf 'MOTIONEYE_STOVE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token motioneye-stove http-proxy prometheus)" >>"$output/gatus.env"
    printf 'NTFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ntfy http-proxy prometheus)" >>"$output/gatus.env"
    printf 'OMADA_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token omada-controller http-proxy prometheus)" >>"$output/gatus.env"
    printf 'OPENSPEEDTEST_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openspeedtest http-proxy prometheus)" >>"$output/gatus.env"
    printf 'PIHOLE_1_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary http-proxy prometheus)" >>"$output/gatus.env"
    printf 'PIHOLE_1_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary http-proxy prometheus)" >>"$output/gatus.env"
    printf 'PIHOLE_2_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary http-proxy prometheus)" >>"$output/gatus.env"
    printf 'PIHOLE_2_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary http-proxy prometheus)" >>"$output/gatus.env"
    printf 'PROMETHEUS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus http-proxy prometheus)" >>"$output/gatus.env"
    printf 'SMTP4DEV_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token smtp4dev http-proxy prometheus)" >>"$output/gatus.env"
    printf 'SPEEDTEST_TRACKER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token speedtest-tracker http-proxy prometheus)" >>"$output/gatus.env"
    printf 'TVHEADEND_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token tvheadend http-proxy prometheus)" >>"$output/gatus.env"
    printf 'UNBOUND_1_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-default http-proxy prometheus)" >>"$output/gatus.env"
    printf 'UNBOUND_1_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-open http-proxy prometheus)" >>"$output/gatus.env"
    printf 'UNBOUND_2_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-default http-proxy prometheus)" >>"$output/gatus.env"
    printf 'UNBOUND_2_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-open http-proxy prometheus)" >>"$output/gatus.env"
    printf 'UNIFI_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unifi-controller http-proxy prometheus)" >>"$output/gatus.env"
    printf 'VAULTWARDEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vaultwarden http-proxy prometheus)" >>"$output/gatus.env"
    # printf 'DESKLAMP_LEFT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-left http-proxy prometheus)" >>"$output/gatus.env"
    # printf 'DESKLAMP_RIGHT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-right http-proxy prometheus)" >>"$output/gatus.env"
    # printf 'NETALERTX_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token netalertx http-proxy prometheus)" >>"$output/gatus.env"
    # printf 'VIKUNJA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vikunja http-proxy prometheus)" >>"$output/gatus.env"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"
    app_prometheus_password="$(load_password "$full_app_name" app prometheus)"
    write_http_auth_user prometheus "$app_prometheus_password"
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$output/all-credentials.csv"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*glances*)
    # App
    admin_password="$(load_password "$full_app_name--$server_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    sh "$helper_script_dir/glances/main.sh" "$admin_password" "$output/glances-password.txt"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name--$server_name"
    app_prometheus_password="$(load_password "$full_app_name--$server_name" app prometheus)"
    write_http_auth_user prometheus "$app_prometheus_password"
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$output/all-credentials.csv"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name--$server_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
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
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*homeassistant*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*homepage*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    write_http_auth_user admin "$admin_password"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    changedetection_apikey="$(load_token changedetection app api-key)"
    printf 'HOMEPAGE_VAR_CHANGEDETECTION_APIKEY=%s\n' "$changedetection_apikey" >>"$output/homepage.env"
    gatus_password="$(load_token gatus-1 app admin)"
    printf 'HOMEPAGE_VAR_GATUS_PASSWORD=%s\n' "$gatus_password" >>"$output/homepage.env"
    gatus_2_password="$(load_token gatus-2 app admin)"
    printf 'HOMEPAGE_VAR_GATUS_2_PASSWORD=%s\n' "$gatus_2_password" >>"$output/homepage.env"
    healthchecks_apikey="$(load_token healthchecks app api-key)"
    printf 'HOMEPAGE_VAR_HEALTHCHECKS_APIKEY=%s\n' "$healthchecks_apikey" >>"$output/homepage.env"
    homeassistant_apikey="$(load_token homeassistant app homepage-api-key)"
    printf 'HOMEPAGE_VAR_HOMEASSISTANT_APIKEY=%s\n' "$homeassistant_apikey" >>"$output/homepage.env"
    jellyfin_apikey="$(load_token jellyfin app homepage-api-key)"
    printf 'HOMEPAGE_VAR_JELLYFIN_PASSWORD=%s\n' "$jellyfin_apikey" >>"$output/homepage.env"
    # TODO: Enable NetAlertX integration
    # netalertx_apikey="$(load_password netalertx app homepage-api-key)"
    # printf 'HOMEPAGE_VAR_NETALERTX_APIKEY=%s\n' "$netalertx_apikey" "$output/homepage.env"
    omadacontroller_password="$(load_token omada-controller app homepage)"
    printf 'HOMEPAGE_VAR_OMADA_CONTROLLER_PASSWORD=%s\n' "$omadacontroller_password" >>"$output/homepage.env"
    pihole1p_apikey="$(load_token pihole-1-primary app api-key)"
    printf 'HOMEPAGE_VAR_PIHOLE_1_PRIMARY_APIKEY=%s\n' "$pihole1p_apikey" >>"$output/homepage.env"
    pihole1s_apikey="$(load_token pihole-1-secondary app api-key)"
    printf 'HOMEPAGE_VAR_PIHOLE_1_SECONDARY_APIKEY=%s\n' "$pihole1s_apikey" >>"$output/homepage.env"
    pihole2p_apikey="$(load_token pihole-2-primary app api-key)"
    printf 'HOMEPAGE_VAR_PIHOLE_2_PRIMARY_APIKEY=%s\n' "$pihole2p_apikey" >>"$output/homepage.env"
    pihole2s_apikey="$(load_token pihole-2-secondary app api-key)"
    printf 'HOMEPAGE_VAR_PIHOLE_2_SECONDARY_APIKEY=%s\n' "$pihole2s_apikey" >>"$output/homepage.env"
    unificontroller_password="$(load_token unifi-controller app homepage)"
    printf 'HOMEPAGE_VAR_UNIFI_CONTROLLER_PASSWORD=%s\n' "$unificontroller_password" >>"$output/homepage.env"
    # TODO: Enable Vikunja integration
    # vikunja_apikey="$(load_password vikunja app homepage-api-key)"
    # printf 'HOMEPAGE_VAR_VIKUNJA_APIKEY=%s\n' "$vikunja_apikey" "$output/homepage.env"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*jellyfin*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
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
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*motioneye*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    user_password="$(load_password "$full_app_name" app user)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
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
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
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
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*openspeedtest*)
    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*pihole*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'FTLCONF_webserver_api_password=%s\n' "$admin_password" >>"$output/pihole.env"

    # Prometheus exporter
    printf 'PIHOLE_PASSWORD=%s\n' "$admin_password" >>"$output/prometheus-exporter.env"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"
    prometheus_password="$(load_password "$full_app_name" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password"
    printf 'prometheus,%s\n' "$prometheus_password" >>"$output/all-credentials.csv"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*prometheus*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    prometheus_password="$(load_token "$full_app_name" app prometheus)"
    printf 'PROMETHEUS_ADMIN_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$admin_password" | base64 | tr -d '\n')" >>"$output/prometheus.env"
    printf 'PROMETHEUS_ADMIN_PASSWORD=%s\n' "$admin_password" >>"$output/prometheus.env"
    printf 'PROMETHEUS_PROMETHEUS_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$prometheus_password" | base64 | tr -d '\n')" >>"$output/prometheus.env"
    printf 'PROMETHEUS_PROMETHEUS_PASSWORD=%s\n' "$prometheus_password" >>"$output/prometheus.env"
    # Other apps prometheus credentials
    printf 'GATUS_1_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 app prometheus)" >>"$output/prometheus.env"
    printf 'GATUS_2_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 app prometheus)" >>"$output/prometheus.env"
    printf 'GLANCES_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--odroid-h3 app prometheus)" >>"$output/prometheus.env"
    printf 'GLANCES_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-3b app prometheus)" >>"$output/prometheus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-2g app prometheus)" >>"$output/prometheus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-4g app prometheus)" >>"$output/prometheus.env"
    printf 'HOMEASSISTANT_PROMETHEUS_TOKEN=%s\n' "$(load_token homeassistant app prometheus-api-key)" >>"$output/prometheus.env"
    printf 'MINIO_PROMETHEUS_TOKEN=%s\n' "$(load_token minio app prometheus-token)" >>"$output/prometheus.env"
    printf 'PIHOLE_1_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary app prometheus)" >>"$output/prometheus.env"
    printf 'PIHOLE_1_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary app prometheus)" >>"$output/prometheus.env"
    printf 'PIHOLE_2_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary app prometheus)" >>"$output/prometheus.env"
    printf 'PIHOLE_2_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary app prometheus)" >>"$output/prometheus.env"
    # Proxy prometheus credentials
    printf 'ACTUALBUDGET_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token actualbudget http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'ACTUALBUDGET_PUBLIC_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token actualbudget-public http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'CHANGEDETECTION_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token changedetection http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'DOCKERHUB_CACHE_PROXY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dockerhub-cache-proxy http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'DOZZLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dozzle http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'GATUS_1_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'GATUS_2_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'GLANCES_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--odroid-h3 http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'GLANCES_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-3b http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-2g http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances--raspberry-pi-4b-4g http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'HEALTHCHECKS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token healthchecks http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'HOMEASSISTANT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homeassistant http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'HOMEPAGE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homepage http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'JELLYFIN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token jellyfin http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'MINIO_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'MINIO_CONSOLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'MOTIONEYE_STOVE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token motioneye-stove http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'NTFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ntfy http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'OMADA_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token omada-controller http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'OPENSPEEDTEST_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openspeedtest http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'PIHOLE_1_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'PIHOLE_1_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'PIHOLE_2_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'PIHOLE_2_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'PROMETHEUS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'SMTP4DEV_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token smtp4dev http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'SPEEDTEST_TRACKER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token speedtest-tracker http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'TVHEADEND_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token tvheadend http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'UNBOUND_1_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-default http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'UNBOUND_1_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-open http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'UNBOUND_2_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-default http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'UNBOUND_2_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-open http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'UNIFI_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unifi-controller http-proxy prometheus)" >>"$output/prometheus.env"
    printf 'VAULTWARDEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vaultwarden http-proxy prometheus)" >>"$output/prometheus.env"
    # printf 'DESKLAMP_LEFT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-left http-proxy prometheus)" >>"$output/prometheus.env"
    # printf 'DESKLAMP_RIGHT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-right http-proxy prometheus)" >>"$output/prometheus.env"
    # printf 'NETALERTX_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token netalertx http-proxy prometheus)" >>"$output/prometheus.env"
    # printf 'VIKUNJA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vikunja http-proxy prometheus)" >>"$output/prometheus.env"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
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
    smb_password="$(load_password "$full_app_name" app admin)"
    printf 'admin,%s\n' "$smb_password" >>"$output/all-credentials.csv"
    printf 'SAMBA_PASSWORD=%s\n' "$smb_password" >>"$output/samba.env"
    ;;
*smtp4dev*)
    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*speedtest-tracker*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    if [ "$mode" = 'dev' ]; then
        admin_email='admin@speedtest-tracker.localhost'
        app_key="$(printf 'base64:' && openssl rand -base64 32)"
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
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*tvheadend*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    user_password="$(load_password "$full_app_name" app user)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"

    # HTTP Proxy
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*unbound*)
    # HTTP Proxy
    write_default_proxy_users "$full_app_name"
    prometheus_password="$(load_password "$full_app_name" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password"
    printf 'prometheus,%s\n' "$prometheus_password" >>"$output/all-credentials.csv"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*unifi-controller*)
    # App
    admin_password="$(load_password "$full_app_name" app admin)"
    viewer_password="$(load_password "$full_app_name" app viewer)"
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
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
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
    write_default_proxy_users "$full_app_name"

    # Certificate Loader
    healthcheck_id="$(load_healthcheck_id "$full_app_name" certificate-loader)"
    write_healthcheck_url certificate-loader "$healthcheck_id"
    ;;
*)
    printf 'Unknown app directory name: %s\n' "$app_dir" >&2
    exit 1
    ;;
esac

# Cleanup
rm -rf "$tmpdir"
