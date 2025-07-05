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
app_dirname="$(basename "$app_dir" | sed -E 's~^\.~~')"
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

load_healthcheck_ping_key() {
    if [ "$mode" = 'prod' ]; then
        bw list items --search 'homelab--healthchecks--app--ping-key' | jq -er ".[] | select(.name == \"homelab--healthchecks--app--ping-key\").login.password"
    else
        printf '\n'
    fi
}

write_healthcheck_url() {
    # $1 - app name
    # $2 - container name
    # $3 - healthchecks ping key

    if [ "$3" = '' ]; then
        healthcheck_url=''
    else
        healthcheck_url="https://healthchecks.matejhome.com/ping/$3/$1-$2"
    fi
    printf 'HOMELAB_HEALTHCHECK_URL=%s\n' "$healthcheck_url" >>"$output/$2.env"
    printf '%s-healthcheck,%s\n' "$2" "$healthcheck_url" >>"$output/all-credentials.csv"
}

write_http_auth_user() {
    # $1 - username
    # $2 - password
    printf '%s' "$2" | chronic htpasswd -c -B -i "$output/$1.htpasswd" "$1"
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
    proxy_status_password="$(load_password "$1" apache status)"
    write_http_auth_user proxy-status "$proxy_status_password"
    printf 'PROXY_STATUS_PASSWORD=%s\n' "$proxy_status_password" >>"$output/apache-prometheus-exporter.env"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$output/all-credentials.csv"
    proxy_prometheus_password="$(load_password "$1" apache prometheus)"
    write_http_auth_user proxy-prometheus "$proxy_prometheus_password"
    printf 'proxy-prometheus,%s\n' "$proxy_prometheus_password" >>"$output/all-credentials.csv"
}

write_certificator_users() {
    # No arguments
    certbot_viewer_password="$(load_token certbot apache viewer)"
    printf 'CERTBOT_VIEWER_PASSWORD=%s\n' "$certbot_viewer_password" >>"$output/certificator.env"
}

case "$app_dirname" in
*actualbudget*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*changedetection*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*certbot*)
    # App
    certbot_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" apache viewer)"
    write_http_auth_user viewer "$certbot_viewer_password"
    printf 'viewer,%s\n' "$certbot_viewer_password" >>"$output/all-credentials.csv"
    certbot_admin_email="$(load_token "$DOCKER_COMPOSE_APP_NAME" certbot admin-email)"
    printf 'CERTBOT_ADMIN_EMAIL=%s\n' "$certbot_admin_email" >>"$output/app.env"
    websupport_api_key="$(load_token "$DOCKER_COMPOSE_APP_NAME" websupport api-key)"
    printf 'WEBSUPPORT_API_KEY=%s\n' "$websupport_api_key" >>"$output/app.env"
    websupport_api_secret="$(load_token "$DOCKER_COMPOSE_APP_NAME" websupport api-secret)"
    printf 'WEBSUPPORT_API_SECRET=%s\n' "$websupport_api_secret" >>"$output/app.env"
    websupport_service_id="$(load_token "$DOCKER_COMPOSE_APP_NAME" websupport service-id)"
    printf 'WEBSUPPORT_SERVICE_ID=%s\n' "$websupport_service_id" >>"$output/app.env"
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" app "$healthcheck_ping_key"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    ;;
*docker-cache-proxy*)
    # App
    http_secret="$(load_password "$DOCKER_COMPOSE_APP_NAME" app http-secret)"
    printf 'REGISTRY_HTTP_SECRET=%s\n' "$http_secret" >>"$output/app.env"
    printf 'REGISTRY_PROXY_USERNAME=\n' >>"$output/app.env"
    printf 'REGISTRY_PROXY_PASSWORD=\n' >>"$output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
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
*dozzle*)
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

    # Apache
    write_default_proxy_users dozzle

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*gatus*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    # Main credentials
    printf 'CERTBOT_VIEWER_PASSWORD=%s\n' "$(load_token certbot apache viewer)" >>"$output/app.env"
    printf 'GATUS_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$admin_password" | base64 | tr -d '\n')" >>"$output/app.env"
    printf 'GLANCES_MACBOOK_PRO_2012_PASSWORD=%s\n' "$(load_token glances-macbook-pro-2012 app admin)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H3_PASSWORD=%s\n' "$(load_token glances-odroid-h3 app admin)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H4_ULTRA_PASSWORD=%s\n' "$(load_token glances-odroid-h4-ultra app admin)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_3B_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-3b app admin)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-2g app admin)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-4g app admin)" >>"$output/app.env"
    printf 'GOTIFY_TOKEN=%s\n' "$(load_token gotify app gatus-token)" >>"$output/app.env"
    printf 'HOMEPAGE_PASSWORD=%s\n' "$(load_token homepage app admin)" >>"$output/app.env"
    printf 'MOTIONEYE_KITCHEN_USER_PASSWORD=%s\n' "$(load_token motioneye-kitchen app user)" >>"$output/app.env"
    printf 'NTFY_TOKEN=%s\n' "$(load_token ntfy app publisher-token)" >>"$output/app.env"
    printf 'SMTP4DEV_PASSWORD=%s\n' "$(load_token smtp4dev app admin)" >>"$output/app.env"
    # Prometheus credentials
    printf 'GATUS_1_PROMETHEUS_TOKEN=%s\n' "$(load_token gatus-1 app prometheus)" >>"$output/app.env"
    printf 'GATUS_2_PROMETHEUS_TOKEN=%s\n' "$(load_token gatus-2 app prometheus)" >>"$output/app.env"
    printf 'GLANCES_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-macbook-pro-2012 app prometheus)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-odroid-h3 app prometheus)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H4_ULTRA_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-odroid-h4-ultra app prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-3b app prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-2g app prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-4g app prometheus)" >>"$output/app.env"
    printf 'HEALTHCHECKS_PROMETHEUS_PROJECT=%s\n' "$(load_token healthchecks app project-id)" >>"$output/app.env"
    printf 'HEALTHCHECKS_PROMETHEUS_TOKEN=%s\n' "$(load_token healthchecks app api-key-readonly)" >>"$output/app.env"
    printf 'HOMEASSISTANT_PROMETHEUS_TOKEN=%s\n' "$(load_token homeassistant app automation-api-key)" >>"$output/app.env"
    printf 'JELLYFIN_PROMETHEUS_TOKEN=%s\n' "$(load_token jellyfin app prometheus)" >>"$output/app.env"
    printf 'MINIO_PROMETHEUS_TOKEN=%s\n' "$(load_token minio app prometheus-token)" >>"$output/app.env"
    printf 'NODE_EXPORTER_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-macbook-pro-2012 app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-odroid-h3 app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_ODROID_H4_ULTRA_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-odroid-h4-ultra app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-3b app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-4b-2g app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-4b-4g app prometheus)" >>"$output/app.env"
    printf 'PIHOLE_1_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary app prometheus)" >>"$output/app.env"
    printf 'PIHOLE_1_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary app prometheus)" >>"$output/app.env"
    printf 'PIHOLE_2_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary app prometheus)" >>"$output/app.env"
    printf 'PIHOLE_2_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary app prometheus)" >>"$output/app.env"
    printf 'PROMETHEUS_PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus app prometheus)" >>"$output/app.env"
    printf 'UPTIME_KUMA_PROMETHEUS_PASSWORD=%s\n' "$(load_token uptime-kuma app admin)" >>"$output/app.env"
    # Proxy prometheus credentials
    printf 'ACTUALBUDGET_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token actualbudget apache prometheus)" >>"$output/app.env"
    printf 'CERTBOT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token certbot apache prometheus)" >>"$output/app.env"
    printf 'CHANGEDETECTION_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token changedetection apache prometheus)" >>"$output/app.env"
    printf 'DOCKER_CACHE_PROXY_DOCKERHUB_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-cache-proxy-dockerhub apache prometheus)" >>"$output/app.env"
    printf 'DOZZLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dozzle apache prometheus)" >>"$output/app.env"
    printf 'GATUS_1_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 apache prometheus)" >>"$output/app.env"
    printf 'GATUS_2_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-macbook-pro-2012 apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-odroid-h3 apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H4_ULTRA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-odroid-h4-ultra apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-3b apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-2g apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-4g apache prometheus)" >>"$output/app.env"
    printf 'GOTIFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gotify apache prometheus)" >>"$output/app.env"
    printf 'HEALTHCHECKS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token healthchecks apache prometheus)" >>"$output/app.env"
    printf 'HOMEASSISTANT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homeassistant apache prometheus)" >>"$output/app.env"
    printf 'HOMEPAGE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homepage apache prometheus)" >>"$output/app.env"
    printf 'JELLYFIN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token jellyfin apache prometheus)" >>"$output/app.env"
    printf 'MINIO_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio apache prometheus)" >>"$output/app.env"
    printf 'MOTIONEYE_KITCHEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token motioneye-kitchen apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-macbook-pro-2012 apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-odroid-h3 apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_ODROID_H4_ULTRA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-odroid-h4-ultra apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-3b apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-4b-2g apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-4b-4g apache prometheus)" >>"$output/app.env"
    printf 'NTFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ntfy apache prometheus)" >>"$output/app.env"
    printf 'OMADA_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token omada-controller apache prometheus)" >>"$output/app.env"
    printf 'OPENSPEEDTEST_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openspeedtest apache prometheus)" >>"$output/app.env"
    printf 'PIHOLE_1_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary apache prometheus)" >>"$output/app.env"
    printf 'PIHOLE_1_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary apache prometheus)" >>"$output/app.env"
    printf 'PIHOLE_2_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary apache prometheus)" >>"$output/app.env"
    printf 'PIHOLE_2_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary apache prometheus)" >>"$output/app.env"
    printf 'PROMETHEUS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus apache prometheus)" >>"$output/app.env"
    printf 'SMTP4DEV_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token smtp4dev apache prometheus)" >>"$output/app.env"
    printf 'SPEEDTEST_TRACKER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token speedtest-tracker apache prometheus)" >>"$output/app.env"
    printf 'TVHEADEND_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token tvheadend apache prometheus)" >>"$output/app.env"
    printf 'UNBOUND_1_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-default apache prometheus)" >>"$output/app.env"
    printf 'UNBOUND_1_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-open apache prometheus)" >>"$output/app.env"
    printf 'UNBOUND_2_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-default apache prometheus)" >>"$output/app.env"
    printf 'UNBOUND_2_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-open apache prometheus)" >>"$output/app.env"
    printf 'UNIFI_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unifi-controller apache prometheus)" >>"$output/app.env"
    printf 'UPTIME_KUMA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token uptime-kuma apache prometheus)" >>"$output/app.env"
    printf 'VAULTWARDEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vaultwarden apache prometheus)" >>"$output/app.env"
    # printf 'DESKLAMP_LEFT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-left apache prometheus)" >>"$output/app.env"
    # printf 'DESKLAMP_RIGHT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-right apache prometheus)" >>"$output/app.env"
    # printf 'NETALERTX_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token netalertx apache prometheus)" >>"$output/app.env"
    # printf 'VIKUNJA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vikunja apache prometheus)" >>"$output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    app_prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$app_prometheus_password"
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$output/all-credentials.csv"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*glances*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    sh "$helper_script_dir/glances/main.sh" "$admin_password" "$output/glances-password.txt"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    app_prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$app_prometheus_password"
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$output/all-credentials.csv"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*gotify*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'GOTIFY_DEFAULTUSER_PASS=%s\n' "$admin_password" >>"$output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*healthchecks*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    if [ "$mode" = 'dev' ]; then
        admin_email='admin@healthchecks.localhost'
    else
        admin_email="admin@$DOCKER_COMPOSE_NETWORK_DOMAIN"
    fi
    printf '%s,%s\n' "$admin_email" "$admin_password" >>"$output/all-credentials.csv"
    secret_key="$(load_password "$DOCKER_COMPOSE_APP_NAME" app secret-key)"
    printf 'SECRET_KEY=%s\n' "$secret_key" >>"$output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*homeassistant*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*homepage*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    write_http_auth_user admin "$admin_password"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'HOMEPAGE_VAR_CHANGEDETECTION_APIKEY=%s\n' "$(load_token changedetection app api-key)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_GATUS_PASSWORD=%s\n' "$(load_token gatus-1 app admin)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_GATUS_2_PASSWORD=%s\n' "$(load_token gatus-2 app admin)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_HEALTHCHECKS_APIKEY=%s\n' "$(load_token healthchecks app api-key-readonly)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_HOMEASSISTANT_APIKEY=%s\n' "$(load_token homeassistant app automation-api-key)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_JELLYFIN_APIKEY=%s\n' "$(load_token jellyfin app automation-api-key)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_MOTIONEYE_KITCHEN_USER_PASSWORD=%s\n' "$(load_token motioneye-kitchen app user)" >>"$output/app.env"
    # TODO: Enable NetAlertX integration
    # printf 'HOMEPAGE_VAR_NETALERTX_APIKEY=%s\n' "$(load_password netalertx app automation-api-key)" "$output/app.env"
    printf 'HOMEPAGE_VAR_OMADA_CONTROLLER_PASSWORD=%s\n' "$(load_token omada-controller app viewer)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_PIHOLE_1_PRIMARY_PASSWORD=%s\n' "$(load_token pihole-1-primary app admin)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_PIHOLE_1_SECONDARY_PASSWORD=%s\n' "$(load_token pihole-1-secondary app admin)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_PIHOLE_2_PRIMARY_PASSWORD=%s\n' "$(load_token pihole-2-primary app admin)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_PIHOLE_2_SECONDARY_PASSWORD=%s\n' "$(load_token pihole-2-secondary app admin)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus app admin)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_SMTP4DEV_PASSWORD=%s\n' "$(load_token smtp4dev app admin)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_SPEEDTEST_TRACKER_APIKEY=%s\n' "$(load_token speedtest-tracker app api-key-readonly)" >>"$output/app.env"
    printf 'HOMEPAGE_VAR_UNIFI_CONTROLLER_PASSWORD=%s\n' "$(load_token unifi-controller app viewer)" >>"$output/app.env"
    # TODO: Enable Vikunja integration
    # printf 'HOMEPAGE_VAR_VIKUNJA_APIKEY=%s\n' "$(load_password vikunja app automation-api-key)" "$output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Widgets
    printf 'PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus app admin)" >>"$output/widgets.env"
    printf 'SMTP4DEV_PASSWORD=%s\n' "$(load_token smtp4dev app admin)" >>"$output/widgets.env"
    ;;
*jellyfin*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password"
    printf 'prometheus,%s\n' "$prometheus_password" >>"$output/all-credentials.csv"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*minio*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    user_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app user)"
    test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app test)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"
    printf 'test,%s\n' "$test_password" >>"$output/all-credentials.csv"
    printf 'MINIO_ROOT_PASSWORD=%s\n' "$admin_password" >>"$output/app.env"

    # Setup
    printf 'MINIO_ADMIN_PASSWORD=%s\n' "$admin_password" >>"$output/app-setup.env"
    printf 'MINIO_USER_PASSWORD=%s\n' "$user_password" >>"$output/app-setup.env"
    printf 'MINIO_TEST_PASSWORD=%s\n' "$test_password" >>"$output/app-setup.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*motioneye*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    user_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app user)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*node-exporter*)
    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    app_prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$app_prometheus_password"
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$output/all-credentials.csv"
    app_debug_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app debug)"
    write_http_auth_user debug "$app_debug_password"
    printf 'app-debug,%s\n' "$app_debug_password" >>"$output/all-credentials.csv"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*ntfy*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    user_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app user)"
    publisher_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app publisher)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"
    printf 'publisher,%s\n' "$publisher_password" >>"$output/all-credentials.csv"
    printf 'NTFY_PASSWORD_ADMIN=%s\n' "$admin_password" >>"$output/app.env"
    printf 'NTFY_PASSWORD_USER=%s\n' "$user_password" >>"$output/app.env"
    printf 'NTFY_PASSWORD_PUBLISHER=%s\n' "$publisher_password" >>"$output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*omada-controller*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app viewer)"
    device_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app device)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'viewer,%s\n' "$viewer_password" >>"$output/all-credentials.csv"
    printf 'device,%s\n' "$device_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*openspeedtest*)
    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*pihole*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'FTLCONF_webserver_api_password=%s\n' "$admin_password" >>"$output/app.env"

    # Prometheus exporter
    printf 'PIHOLE_PASSWORD=%s\n' "$admin_password" >>"$output/app-prometheus-exporter.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password"
    printf 'prometheus,%s\n' "$prometheus_password" >>"$output/all-credentials.csv"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*prometheus*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    prometheus_password="$(load_token "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    printf 'PROMETHEUS_ADMIN_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$admin_password" | base64 | tr -d '\n')" >>"$output/app.env"
    printf 'PROMETHEUS_ADMIN_PASSWORD=%s\n' "$admin_password" >>"$output/app.env"
    printf 'PROMETHEUS_PROMETHEUS_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$prometheus_password" | base64 | tr -d '\n')" >>"$output/app.env"
    printf 'PROMETHEUS_PROMETHEUS_PASSWORD=%s\n' "$prometheus_password" >>"$output/app.env"
    # Other apps prometheus credentials
    printf 'GATUS_1_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 app prometheus)" >>"$output/app.env"
    printf 'GATUS_2_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 app prometheus)" >>"$output/app.env"
    printf 'GLANCES_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-macbook-pro-2012 app prometheus)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-odroid-h3 app prometheus)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H4_ULTRA_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-odroid-h4-ultra app prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-3b app prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-2g app prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-4g app prometheus)" >>"$output/app.env"
    printf 'HEALTHCHECKS_PROMETHEUS_PROJECT=%s\n' "$(load_token healthchecks app project-id)" >>"$output/app.env"
    printf 'HEALTHCHECKS_PROMETHEUS_TOKEN=%s\n' "$(load_token healthchecks app api-key-readonly)" >>"$output/app.env"
    printf 'HOMEASSISTANT_PROMETHEUS_TOKEN=%s\n' "$(load_token homeassistant app automation-api-key)" >>"$output/app.env"
    printf 'JELLYFIN_PROMETHEUS_PASSWORD=%s\n' "$(load_token jellyfin app prometheus)" >>"$output/app.env"
    printf 'MINIO_PROMETHEUS_TOKEN=%s\n' "$(load_token minio app prometheus-token)" >>"$output/app.env"
    printf 'NODE_EXPORTER_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-macbook-pro-2012 app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-odroid-h3 app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_ODROID_H4_ULTRA_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-odroid-h4-ultra app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-3b app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-4b-2g app prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-4b-4g app prometheus)" >>"$output/app.env"
    printf 'PIHOLE_1_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary app prometheus)" >>"$output/app.env"
    printf 'PIHOLE_1_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary app prometheus)" >>"$output/app.env"
    printf 'PIHOLE_2_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary app prometheus)" >>"$output/app.env"
    printf 'PIHOLE_2_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary app prometheus)" >>"$output/app.env"
    printf 'UPTIME_KUMA_PROMETHEUS_PASSWORD=%s\n' "$(load_token uptime-kuma app admin)" >>"$output/app.env"
    # Proxy prometheus credentials
    printf 'ACTUALBUDGET_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token actualbudget apache prometheus)" >>"$output/app.env"
    printf 'CERTBOT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token certbot apache prometheus)" >>"$output/app.env"
    printf 'CHANGEDETECTION_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token changedetection apache prometheus)" >>"$output/app.env"
    printf 'DOCKER_CACHE_PROXY_DOCKERHUB_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-cache-proxy-dockerhub apache prometheus)" >>"$output/app.env"
    printf 'DOZZLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dozzle apache prometheus)" >>"$output/app.env"
    printf 'GATUS_1_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 apache prometheus)" >>"$output/app.env"
    printf 'GATUS_2_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-macbook-pro-2012 apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-odroid-h3 apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_ODROID_H4_ULTRA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-odroid-h4-ultra apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-3b apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-2g apache prometheus)" >>"$output/app.env"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token glances-raspberry-pi-4b-4g apache prometheus)" >>"$output/app.env"
    printf 'GOTIFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gotify apache prometheus)" >>"$output/app.env"
    printf 'HEALTHCHECKS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token healthchecks apache prometheus)" >>"$output/app.env"
    printf 'HOMEASSISTANT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homeassistant apache prometheus)" >>"$output/app.env"
    printf 'HOMEPAGE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homepage apache prometheus)" >>"$output/app.env"
    printf 'JELLYFIN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token jellyfin apache prometheus)" >>"$output/app.env"
    printf 'MINIO_CONSOLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio apache prometheus)" >>"$output/app.env"
    printf 'MINIO_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio apache prometheus)" >>"$output/app.env"
    printf 'MOTIONEYE_KITCHEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token motioneye-kitchen apache prometheus)" >>"$output/app.env"
    printf 'NETALERTX_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token netalertx apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-macbook-pro-2012 apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-odroid-h3 apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_ODROID_H4_ULTRA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-odroid-h4-ultra apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-3b apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-4b-2g apache prometheus)" >>"$output/app.env"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token node-exporter-raspberry-pi-4b-4g apache prometheus)" >>"$output/app.env"
    printf 'NTFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ntfy apache prometheus)" >>"$output/app.env"
    printf 'OMADA_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token omada-controller apache prometheus)" >>"$output/app.env"
    printf 'OPENSPEEDTEST_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openspeedtest apache prometheus)" >>"$output/app.env"
    printf 'PIHOLE_1_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary apache prometheus)" >>"$output/app.env"
    printf 'PIHOLE_1_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary apache prometheus)" >>"$output/app.env"
    printf 'PIHOLE_2_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary apache prometheus)" >>"$output/app.env"
    printf 'PIHOLE_2_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary apache prometheus)" >>"$output/app.env"
    printf 'PROMETHEUS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus apache prometheus)" >>"$output/app.env"
    printf 'SMTP4DEV_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token smtp4dev apache prometheus)" >>"$output/app.env"
    printf 'SPEEDTEST_TRACKER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token speedtest-tracker apache prometheus)" >>"$output/app.env"
    printf 'TVHEADEND_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token tvheadend apache prometheus)" >>"$output/app.env"
    printf 'UNBOUND_1_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-default apache prometheus)" >>"$output/app.env"
    printf 'UNBOUND_1_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-open apache prometheus)" >>"$output/app.env"
    printf 'UNBOUND_2_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-default apache prometheus)" >>"$output/app.env"
    printf 'UNBOUND_2_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-open apache prometheus)" >>"$output/app.env"
    printf 'UNIFI_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unifi-controller apache prometheus)" >>"$output/app.env"
    printf 'UPTIME_KUMA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token uptime-kuma apache prometheus)" >>"$output/app.env"
    printf 'VAULTWARDEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vaultwarden apache prometheus)" >>"$output/app.env"
    printf 'VIKUNJA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vikunja apache prometheus)" >>"$output/app.env"
    # printf 'DESKLAMP_LEFT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-left apache prometheus)" >>"$output/app.env"
    # printf 'DESKLAMP_RIGHT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-right apache prometheus)" >>"$output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*renovatebot*)
    # App
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" app "$healthcheck_ping_key"
    renovate_token="$(load_token "$DOCKER_COMPOSE_APP_NAME" app renovate-token)" # PAT specific for each git host
    github_token="$(load_token "$DOCKER_COMPOSE_APP_NAME" app github-token)"     # GitHub PAT (even if using other git hosts)
    printf 'RENOVATE_TOKEN=%s\n' "$renovate_token" >>"$output/app.env"
    printf 'GITHUB_COM_TOKEN=%s\n' "$github_token" >>"$output/app.env"
    ;;
*samba*)
    # App
    smb_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$smb_password" >>"$output/all-credentials.csv"
    printf 'SAMBA_PASSWORD=%s\n' "$smb_password" >>"$output/app.env"
    ;;
*smtp4dev*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'ServerOptions__Users__0__Password=%s\n' "$admin_password" >>"$output/app.env"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*speedtest-tracker*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    if [ "$mode" = 'dev' ]; then
        admin_email='admin@speedtest-tracker.localhost'
        app_key="$(printf 'base64:' && openssl rand -base64 32)"
    else
        admin_email="admin@$DOCKER_COMPOSE_NETWORK_DOMAIN"
        app_key="$(load_token "$DOCKER_COMPOSE_APP_NAME" app app-key)"
    fi
    printf '%s,%s\n' "$admin_email" "$admin_password" >>"$output/all-credentials.csv"
    printf 'APP_KEY=%s\n' "$app_key" >>"$output/app.env"
    printf 'ADMIN_NAME=Admin\n' >>"$output/app.env"
    printf 'ADMIN_EMAIL=%s\n' "$admin_email" >>"$output/app.env"
    printf 'ADMIN_PASSWORD=%s\n' "$admin_password" >>"$output/app.env"
    printf 'MAIL_PASSWORD=\n' >>"$output/app.env"
    printf 'MAIL_USERNAME=\n' >>"$output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*tvheadend*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    user_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app user)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'user,%s\n' "$user_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*unbound*)
    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password"
    printf 'prometheus,%s\n' "$prometheus_password" >>"$output/all-credentials.csv"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*unifi-controller*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app viewer)"
    mongodb_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" mongodb admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"
    printf 'viewer,%s\n' "$viewer_password" >>"$output/all-credentials.csv"
    printf 'mongodb,%s\n' "$mongodb_password" >>"$output/all-credentials.csv"

    # Database
    printf 'MONGO_PASSWORD=%s\n' "$mongodb_password" >>"$output/mongodb.env"
    printf '%s' "$mongodb_password" >>"$output/mongodb-password.txt"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*uptime-kuma*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*vaultwarden*)
    # App
    superadmin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app superadmin)"
    superadmin_password_hashed="$(printf '%s' "$superadmin_password" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4 | sed 's~\$~$$~g')"
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    if [ "$mode" = 'dev' ]; then
        admin_email='admin@vaultwarden.localhost'
    else
        admin_email="admin@$DOCKER_COMPOSE_NETWORK_DOMAIN"
    fi
    homelab_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab)"
    if [ "$mode" = 'dev' ]; then
        homelab_email='homelab@vaultwarden.localhost'
    else
        homelab_email="homelab@$DOCKER_COMPOSE_NETWORK_DOMAIN"
    fi
    printf 'ADMIN_TOKEN=%s\n' "$superadmin_password_hashed" >>"$output/app.env"
    printf 'superadmin,%s\n' "$superadmin_password" >>"$output/all-credentials.csv"
    printf '%s,%s\n' "$admin_email" "$admin_password" >>"$output/all-credentials.csv"
    printf '%s,%s\n' "$homelab_email" "$homelab_password" >>"$output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    healthcheck_ping_key="$(load_healthcheck_ping_key)"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"
    ;;
*)
    printf 'Unknown app directory name: %s\n' "$app_dir" >&2
    exit 1
    ;;
esac

find "$output" -type f -exec chmod 0400 {} \;

# Cleanup
rm -rf "$tmpdir"
