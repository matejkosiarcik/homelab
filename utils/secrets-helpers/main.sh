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
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d | --dev)
        mode='dev'
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

initial_output="$(mktemp -d)"
printf 'user,password\n' >"$initial_output/all-credentials.csv"

app_dir="$PWD"
app_dirname="$(basename "$app_dir" | sed -E 's~^\.~~')"
tmpdir="$(mktemp -d)"

if [ "$mode" = 'prod' ]; then
    healthcheck_ping_key="$(bw list items --search 'healthchecks__app__ping_key' | jq -er '.[] | select(.name == "healthchecks__app__ping_key").login.password')"
else
    healthcheck_ping_key=''
fi

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

    itemname="$(printf '%s--%s--%s' "$1" "$2" "$3" | tr '-' '_')"
    if [ "$mode" = 'prod' ]; then
        {
            bw list items --search "$itemname" | jq -er ".[] | select(.name == \"$itemname\").login.username"
        } || {
            printf 'Could not load %s\n' "$itemname" >&2
            exit 1
        }
    else
        printf '%s\n' "$3"
    fi
}

load_password() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    itemname="$(printf '%s--%s--%s' "$1" "$2" "$3" | tr '-' '_')"
    if [ "$mode" = 'prod' ]; then
        {
            bw list items --search "$itemname" | jq -er ".[] | select(.name == \"$itemname\").login.password"
        } || {
            printf 'Could not load %s\n' "$itemname" >&2
            exit 1
        }
    else
        printf 'Password123.\n'
    fi
}

load_token() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    itemname="$(printf '%s--%s--%s' "$1" "$2" "$3" | tr '-' '_')"
    if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
        {
            bw list items --search "$itemname" | jq -er ".[] | select(.name == \"$itemname\").login.password"
        } || {
            printf 'Could not load %s\n' "$itemname" >&2
            exit 1
        }
    else
        printf '\n'
    fi
}

load_notes() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    itemname="$(printf '%s--%s--%s' "$1" "$2" "$3" | tr '-' '_')"
    if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
        {
            bw list items --search "$itemname" | jq -er ".[] | select(.name == \"$itemname\").notes"
        } || {
            printf 'Could not load %s\n' "$itemname" >&2
            exit 1
        }
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
    printf 'HOMELAB_HEALTHCHECK_URL=%s\n' "$healthcheck_url" >>"$initial_output/$2.env"
    printf '%s-healthcheck,%s\n' "$2" "$healthcheck_url" >>"$initial_output/all-credentials.csv"
}

write_http_auth_user() {
    # $1 - username
    # $2 - password
    # $3 - file
    tmpdir_htpasswd="$(mktemp -d)"
    printf '%s' "$2" | chronic htpasswd -c -B -i "$tmpdir_htpasswd/file.htpasswd" "$1"
    cat "$tmpdir_htpasswd/file.htpasswd" >>"$initial_output/$3.htpasswd"
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
    write_http_auth_user proxy-status "$proxy_status_password" proxy-status
    printf 'PROXY_STATUS_PASSWORD=%s\n' "$proxy_status_password" >>"$initial_output/apache-prometheus-exporter.env"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$initial_output/all-credentials.csv"
    proxy_prometheus_password="$(load_password "$1" apache prometheus)"
    write_http_auth_user proxy-prometheus "$proxy_prometheus_password" proxy-prometheus
    printf 'proxy-prometheus,%s\n' "$proxy_prometheus_password" >>"$initial_output/all-credentials.csv"
}

write_certificator_users() {
    # No arguments
    certbot_homelab_viewer_password="$(load_token certbot app homelab-viewer)"
    printf 'CERTBOT_HOMELAB_VIEWER_PASSWORD=%s\n' "$certbot_homelab_viewer_password" >>"$initial_output/certificator.env"
}

case "$app_dirname" in
*actualbudget*)
    # App
    printf 'admin,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*adventurelog*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'monika,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app monika)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"
    django_admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app django-admin)"
    printf 'DJANGO_ADMIN_PASSWORD=%s\n' "$django_admin_password" >>"$initial_output/app-backend.env"
    printf 'django-admin,%s\n' "$django_admin_password" >>"$initial_output/all-credentials.csv"
    secret_key="$(load_password "$DOCKER_COMPOSE_APP_NAME" app secret-key)"
    printf 'SECRET_KEY=%s\n' "$secret_key" >>"$initial_output/app-backend.env"
    printf 'secret-key,%s\n' "$secret_key" >>"$initial_output/all-credentials.csv"

    # Database
    database_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" database user)"
    printf 'PGPASSWORD=%s\n' "$database_password" >>"$initial_output/app-backend.env"
    printf 'POSTGRES_PASSWORD=%s\n' "$database_password" >>"$initial_output/postgis.env"
    printf 'database,%s\n' "$database_password" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*changedetection*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*certbot*)
    # App
    certbot_matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    write_http_auth_user matej "$certbot_matej_password" proxy-prometheus
    write_http_auth_user matej "$certbot_matej_password" users-viewers
    write_http_auth_user matej "$certbot_matej_password" users-admins
    printf 'matej,%s\n' "$certbot_matej_password" >>"$initial_output/all-credentials.csv"
    certbot_homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    write_http_auth_user homelab-viewer "$certbot_homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$certbot_homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$certbot_homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    certbot_homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    write_http_auth_user homelab-test "$certbot_homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$certbot_homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$certbot_homelab_test_password" >>"$initial_output/all-credentials.csv"
    certbot_public_email="$(load_token "$DOCKER_COMPOSE_APP_NAME" app public-email)"
    printf 'CERTBOT_PUBLIC_EMAIL=%s\n' "$certbot_public_email" >>"$initial_output/app.env"
    websupport_api_key="$(load_token "$DOCKER_COMPOSE_APP_NAME" websupport api-key)"
    printf 'WEBSUPPORT_API_KEY=%s\n' "$websupport_api_key" >>"$initial_output/app.env"
    websupport_api_secret="$(load_token "$DOCKER_COMPOSE_APP_NAME" websupport api-secret)"
    printf 'WEBSUPPORT_API_SECRET=%s\n' "$websupport_api_secret" >>"$initial_output/app.env"
    websupport_service_id="$(load_token "$DOCKER_COMPOSE_APP_NAME" websupport service-id)"
    printf 'WEBSUPPORT_SERVICE_ID=%s\n' "$websupport_service_id" >>"$initial_output/app.env"
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" app "$healthcheck_ping_key"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*dawarich*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"
    printf 'api-key,%s\n' "$(load_token "$DOCKER_COMPOSE_APP_NAME" app api-key)" >>"$initial_output/all-credentials.csv"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"

    # Database
    database_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" database user)"
    printf 'DATABASE_PASSWORD=%s\n' "$database_password" >>"$initial_output/app.env"
    printf 'POSTGRES_PASSWORD=%s\n' "$database_password" >>"$initial_output/postgis.env"
    printf 'database,%s\n' "$database_password" >>"$initial_output/all-credentials.csv"

    # Decryptor
    secret_key="$(load_token "$DOCKER_COMPOSE_APP_NAME" app secret-key)"
    printf 'SECRET_KEY=%s\n' "$secret_key" >>"$initial_output/decryptor.env"
    printf 'secret-key,%s\n' "$secret_key" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*docker-cache-proxy*)
    # App
    http_secret="$(load_password "$DOCKER_COMPOSE_APP_NAME" app http-secret)"
    printf 'REGISTRY_HTTP_SECRET=%s\n' "$http_secret" >>"$initial_output/app.env"
    printf 'REGISTRY_PROXY_USERNAME=\n' >>"$initial_output/app.env"
    printf 'REGISTRY_PROXY_PASSWORD=\n' >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*docker-stats*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*dozzle-agent*)
    # App
    if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
        app_key="$(load_notes dozzle app key)"
        printf '%s\n' "$app_key" >"$initial_output/dozzle-key.pem"
        app_cert="$(load_notes dozzle app cert)"
        printf '%s\n' "$app_cert" >"$initial_output/dozzle-cert.pem"
    else
        sh "$helper_script_dir/dozzle/main.sh" "$initial_output"
    fi
    ;;
*dozzle*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    hash_password_bcrypt "$matej_password" >"$tmpdir/matej-password-encrypted.txt"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    hash_password_bcrypt "$homelab_test_password" >"$tmpdir/homelab-test-password-encrypted.txt"
    printf 'users:\n matej:\n  email: matej@%s\n  name: matej\n  password: %s\n homelab-test:\n  email: homelab-test@homelab.%s\n  name: homelab-test\n  password: %s\n' "$DOCKER_COMPOSE_NETWORK_DOMAIN" "$(cat "$tmpdir/matej-password-encrypted.txt")" "$DOCKER_COMPOSE_NETWORK_DOMAIN" "$(cat "$tmpdir/homelab-test-password-encrypted.txt")" |
        sed -E 's~^( +)~\1\1\1\1~' >"$initial_output/dozzle-users.yml"
    if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
        app_key="$(load_notes dozzle app key)"
        printf '%s\n' "$app_key" >"$initial_output/dozzle-key.pem"
        app_cert="$(load_notes dozzle app cert)"
        printf '%s\n' "$app_cert" >"$initial_output/dozzle-cert.pem"
    else
        sh "$helper_script_dir/dozzle/main.sh" "$initial_output"
    fi

    # Apache
    write_default_proxy_users dozzle

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*gatus*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    printf 'PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$matej_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    # Main credentials
    printf 'CERTBOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token certbot app homelab-viewer)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h3 app homelab-viewer)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h4-ultra app homelab-viewer)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-2g app homelab-viewer)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-4g app homelab-viewer)" >>"$initial_output/app.env"
    printf 'GATUS_1__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token gatus-1 app homelab-viewer)" >>"$initial_output/app.env"
    printf 'GATUS_2__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token gatus-2 app homelab-viewer)" >>"$initial_output/app.env"
    printf 'GOTIFY__TOKEN=%s\n' "$(load_token gotify app gatus-token)" >>"$initial_output/app.env"
    printf 'HOMEPAGE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token homepage app homelab-viewer)" >>"$initial_output/app.env"
    printf 'MOTIONEYE_KITCHEN__HOMELAB_STREAM_PASSWORD=%s\n' "$(load_token motioneye-kitchen app homelab-stream)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h3 app homelab-viewer)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h4-ultra app homelab-viewer)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-2g app homelab-viewer)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-4g app homelab-viewer)" >>"$initial_output/app.env"
    printf 'NTFY__TOKEN=%s\n' "$(load_token ntfy app homelab-publisher-token)" >>"$initial_output/app.env"
    printf 'OLLAMA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token ollama app homelab-viewer)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token ollama-private app homelab-viewer)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token prometheus app homelab-viewer)" >>"$initial_output/app.env"
    printf 'RENOVATEBOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token renovatebot app homelab-viewer)" >>"$initial_output/app.env"
    printf 'SMTP4DEV__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token smtp4dev app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-1-default app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-1-guests app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-1-iot app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-1-matej app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-1-monika app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-1-internal app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-1-blackhole app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-2-default app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-2-guests app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-2-iot app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-2-matej app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-2-monika app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-2-internal app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token unbound-2-blackhole app homelab-viewer)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__MATEJ_PASSWORD=%s\n' "$(load_token uptimekuma-1 app matej)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__MATEJ_PASSWORD=%s\n' "$(load_token uptimekuma-2 app matej)" >>"$initial_output/app.env"
    printf 'WIKIPEDIA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token kiwix-wikipedia app homelab-viewer)" >>"$initial_output/app.env"
    printf 'WIKTIONARY__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_token kiwix-wiktionary app homelab-viewer)" >>"$initial_output/app.env"
    # Prometheus credentials
    printf 'DAWARICH__PROMETHEUS_PASSWORD=%s\n' "$(load_token dawarich app prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h3 app prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h4-ultra app prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-2g app prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-4g app prometheus)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 app prometheus)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 app prometheus)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_PROJECT=%s\n' "$(load_token healthchecks app project-id)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_TOKEN=%s\n' "$(load_token healthchecks app api-key-readonly)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROMETHEUS_TOKEN=%s\n' "$(load_token homeassistant app homelab-viewer-api-key)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROMETHEUS_PASSWORD=%s\n' "$(load_token jellyfin app prometheus)" >>"$initial_output/app.env"
    printf 'MINIO__PROMETHEUS_TOKEN=%s\n' "$(load_token minio app prometheus-token)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h3 app prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h4-ultra app prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-2g app prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-4g app prometheus)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__PROMETHEUS_PASSWORD=%s\n' "$(load_token ollama-private app prometheus)" >>"$initial_output/app.env"
    printf 'OLLAMA__PROMETHEUS_PASSWORD=%s\n' "$(load_token ollama app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-blackhole app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-blackhole app prometheus)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus app prometheus)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROMETHEUS_PASSWORD=%s\n' "$(load_token samba-data app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-default app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-guests app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-iot app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-matej app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-monika app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-internal app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-blackhole app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-default app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-guests app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-iot app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-matej app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-monika app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-internal app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-blackhole app prometheus)" >>"$initial_output/app.env"
    # Proxy prometheus credentials
    printf 'ACTUALBUDGET__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token actualbudget apache prometheus)" >>"$initial_output/app.env"
    printf 'CERTBOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token certbot apache prometheus)" >>"$initial_output/app.env"
    printf 'CHANGEDETECTION__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token changedetection apache prometheus)" >>"$initial_output/app.env"
    printf 'DAWARICH__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dawarich apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_CACHE_PROXY_DOCKERHUB__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-cache-proxy-dockerhub apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h3 apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h4-ultra apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-2g apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-4g apache prometheus)" >>"$initial_output/app.env"
    printf 'DOZZLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dozzle apache prometheus)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 apache prometheus)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 apache prometheus)" >>"$initial_output/app.env"
    printf 'GOTIFY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gotify apache prometheus)" >>"$initial_output/app.env"
    printf 'GRAFANA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token grafana apache prometheus)" >>"$initial_output/app.env"
    printf 'GROCERIES__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token groceries apache prometheus)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token healthchecks apache prometheus)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homeassistant apache prometheus)" >>"$initial_output/app.env"
    printf 'HOMEPAGE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homepage apache prometheus)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token jellyfin apache prometheus)" >>"$initial_output/app.env"
    printf 'MINIO_CONSOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio apache prometheus)" >>"$initial_output/app.env"
    printf 'MINIO__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio apache prometheus)" >>"$initial_output/app.env"
    printf 'MOTIONEYE_KITCHEN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token motioneye-kitchen apache prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h3 apache prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h4-ultra apache prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-2g apache prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-4g apache prometheus)" >>"$initial_output/app.env"
    printf 'NTFY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ntfy apache prometheus)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ollama-private apache prometheus)" >>"$initial_output/app.env"
    printf 'OLLAMA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ollama apache prometheus)" >>"$initial_output/app.env"
    printf 'OMADACONTROLLER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token omadacontroller apache prometheus)" >>"$initial_output/app.env"
    printf 'OPENSPEEDTEST__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openspeedtest apache prometheus)" >>"$initial_output/app.env"
    printf 'OPENWEBUI_PRIVATE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openwebui-private apache prometheus)" >>"$initial_output/app.env"
    printf 'OPENWEBUI__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openwebui apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-blackhole apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-blackhole apache prometheus)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus apache prometheus)" >>"$initial_output/app.env"
    printf 'RENOVATEBOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token renovatebot apache prometheus)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token samba-data apache prometheus)" >>"$initial_output/app.env"
    printf 'SMTP4DEV__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token smtp4dev apache prometheus)" >>"$initial_output/app.env"
    printf 'SPEEDTESTTRACKER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token speedtesttracker apache prometheus)" >>"$initial_output/app.env"
    printf 'TVHEADEND__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token tvheadend apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-default apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-guests apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-iot apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-matej apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-monika apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-internal apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-blackhole apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-default apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-guests apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-iot apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-matej apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-monika apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-internal apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-blackhole apache prometheus)" >>"$initial_output/app.env"
    printf 'UNIFICONTROLLER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unificontroller apache prometheus)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token uptimekuma-1 apache prometheus)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token uptimekuma-2 apache prometheus)" >>"$initial_output/app.env"
    printf 'VAULTWARDEN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vaultwarden apache prometheus)" >>"$initial_output/app.env"
    printf 'WIKIPEDIA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token kiwix-wikipedia apache prometheus)" >>"$initial_output/app.env"
    printf 'WIKTIONARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token kiwix-wiktionary apache prometheus)" >>"$initial_output/app.env"
    # printf 'DESKLAMP_LEFT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-left apache prometheus)" >>"$initial_output/app.env"
    # printf 'DESKLAMP_RIGHT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-right apache prometheus)" >>"$initial_output/app.env"
    # printf 'NETALERTX_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token netalertx apache prometheus)" >>"$initial_output/app.env"
    # printf 'VIKUNJA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vikunja apache prometheus)" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*gotify*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    printf 'GOTIFY_DEFAULTUSER_PASS=%s\n' "$matej_password" >>"$initial_output/app.env"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*grafana*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    printf 'GF_SECURITY_ADMIN_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app.env"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*groceries*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    monika_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app monika)"
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    printf 'SMTP_PASSWORD=\n' >>"$initial_output/app.env" # Placeholder

    # Database
    database_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" couchdb admin)"
    printf 'COUCHDB_ADMIN_PASSWORD=%s\n' "$database_password" >>"$initial_output/app.env"
    printf 'COUCHDB_PASSWORD=%s\n' "$database_password" >>"$initial_output/couchdb.env"
    printf 'couchdb-admin,%s\n' "$database_password" >>"$initial_output/all-credentials.csv"
    hmac_key="$(load_password "$DOCKER_COMPOSE_APP_NAME" couchdb hmac-key)"
    printf 'COUCHDB_HMAC_KEY=%s\n' "$hmac_key" >>"$initial_output/app.env"
    printf 'HMAC_KEY=%s\n' "$hmac_key" >>"$initial_output/couchdb.env"
    printf 'couchdb-hmac,%s\n' "$hmac_key" >>"$initial_output/all-credentials.csv"
    uuid="$(load_token "$DOCKER_COMPOSE_APP_NAME" couchdb uuid)"
    printf 'UUID=%s\n' "$uuid" >>"$initial_output/couchdb.env"
    printf 'couchdb-uuid,%s\n' "$uuid" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*healthchecks*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"
    secret_key="$(load_password "$DOCKER_COMPOSE_APP_NAME" app secret-key)"
    printf 'SECRET_KEY=%s\n' "$secret_key" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*homeassistant*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'monika,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app monika)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-admin,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-admin)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-viewer,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*homepage*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    printf 'HOMEPAGE_VAR__CHANGEDETECTION__APIKEY=%s\n' "$(load_token changedetection app api-key)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__GATUS_1__PASSWORD=%s\n' "$(load_token gatus-1 app homelab-viewer)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__GATUS_2__PASSWORD=%s\n' "$(load_token gatus-2 app homelab-viewer)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__GRAFANA__PASSWORD=%s\n' "$(load_token grafana app homelab-viewer)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__HEALTHCHECKS__APIKEY=%s\n' "$(load_token healthchecks app api-key-readonly)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__HOMEASSISTANT__APIKEY=%s\n' "$(load_token homeassistant app homelab-viewer-api-key)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__JELLYFIN__APIKEY=%s\n' "$(load_token jellyfin app homelab-api-key)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__MOTIONEYE_KITCHEN__HOMELAB_STREAM_PASSWORD=%s\n' "$(load_token motioneye-kitchen app homelab-stream)" >>"$initial_output/app.env"
    # TODO: Enable NetAlertX integration
    # printf 'HOMEPAGE_VAR_NETALERTX_APIKEY=%s\n' "$(load_token netalertx app api-key)" "$initial_output/app.env"
    printf 'HOMEPAGE_VAR__OMADACONTROLLER__PASSWORD=%s\n' "$(load_token omadacontroller app homelab-viewer)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_1_PRIMARY__PASSWORD=%s\n' "$(load_token pihole-1-primary app admin)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_1_SECONDARY__PASSWORD=%s\n' "$(load_token pihole-1-secondary app admin)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_1_BLACKHOLE__PASSWORD=%s\n' "$(load_token pihole-1-blackhole app admin)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_2_PRIMARY__PASSWORD=%s\n' "$(load_token pihole-2-primary app admin)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_2_SECONDARY__PASSWORD=%s\n' "$(load_token pihole-2-secondary app admin)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_2_BLACKHOLE__PASSWORD=%s\n' "$(load_token pihole-2-blackhole app admin)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PROMETHEUS__PASSWORD=%s\n' "$(load_token prometheus app homelab-viewer)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__SPEEDTESTTRACKER__APIKEY=%s\n' "$(load_token speedtesttracker app api-key-readonly)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__UNIFICONTROLLER__PASSWORD=%s\n' "$(load_token unificontroller app homelab-viewer)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__VIKUNJA__APIKEY=%s\n' "$(load_token vikunja app api-key-readonly)" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    printf 'FAVICON_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/favicons.env"

    # Widgets
    printf 'PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus app homelab-viewer)" >>"$initial_output/widgets.env"
    printf 'SMTP4DEV_PASSWORD=%s\n' "$(load_token smtp4dev app homelab-viewer)" >>"$initial_output/widgets.env"
    ;;
*jellyfin*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'monika,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app monika)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-admin,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-admin)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-viewer,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*kiwix*)
    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    monika_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app monika)"
    write_http_auth_user monika "$monika_password" users-viewers
    write_http_auth_user monika "$monika_password" users-admins
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/all-credentials.csv"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*minio*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    homelab_writer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-writer)"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    printf 'homelab-writer,%s\n' "$homelab_writer_password" >>"$initial_output/all-credentials.csv"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    printf 'MINIO_ROOT_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app.env"

    # Setup
    printf 'MINIO_MATEJ_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app-setup.env"
    printf 'MINIO_HOMELAB_WRITER_PASSWORD=%s\n' "$homelab_writer_password" >>"$initial_output/app-setup.env"
    printf 'MINIO_HOMELAB_VIEWER_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/app-setup.env"
    printf 'MINIO_HOMELAB_TEST_PASSWORD=%s\n' "$homelab_test_password" >>"$initial_output/app-setup.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*motioneye*)
    # App
    printf 'admin,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)" >>"$initial_output/all-credentials.csv"
    printf 'stream,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-stream)" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*nodeexporter*)
    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*ntfy*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    printf 'NTFY_PASSWORD_MATEJ=%s\n' "$matej_password" >>"$initial_output/app.env"
    homelab_publisher_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-publisher)"
    printf 'homelab-publisher,%s\n' "$homelab_publisher_password" >>"$initial_output/all-credentials.csv"
    printf 'NTFY_PASSWORD_HOMELAB_PUBLISHER=%s\n' "$homelab_publisher_password" >>"$initial_output/app.env"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    printf 'NTFY_PASSWORD_HOMELAB_VIEWER=%s\n' "$homelab_viewer_password" >>"$initial_output/app.env"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    printf 'NTFY_PASSWORD_HOMELAB_TEST=%s\n' "$homelab_test_password" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*ollama*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    openwebui_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app openwebui)"
    write_http_auth_user openwebui "$openwebui_password" users-viewers
    write_http_auth_user openwebui "$openwebui_password" users-admins
    printf 'openwebui,%s\n' "$openwebui_password" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*omadacontroller*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-admin,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-admin)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-viewer,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*openspeedtest*)
    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*openwebui*)
    # App
    ollama_openwebui_password="$(load_token ollama app openwebui)"
    printf 'OLLAMA_BASE_URL=%s\n' "https://openwebui:$ollama_openwebui_password@$DOCKER_COMPOSE_OLLAMA_UPSTREAM_DOMAIN" >>"$initial_output/app.env"
    secret_key="$(load_token "$DOCKER_COMPOSE_APP_NAME" app secret-key)"
    printf 'WEBUI_SECRET_KEY=%s\n' "$secret_key" >>"$initial_output/app.env"
    printf 'secret-key,%s\n' "$secret_key" >>"$initial_output/all-credentials.csv"
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*pihole*)
    # App
    admin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/all-credentials.csv"
    printf 'FTLCONF_webserver_api_password=%s\n' "$admin_password" >>"$initial_output/app.env"

    # Prometheus exporter
    printf 'PIHOLE_PASSWORD=%s\n' "$admin_password" >>"$initial_output/app-prometheus-exporter.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*prometheus*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    printf 'PROMETHEUS__MATEJ_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$matej_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$homelab_viewer_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/app.env"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    printf 'PROMETHEUS__HOMELAB_TEST_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$homelab_test_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    printf 'prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$prometheus_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user prometheus "$matej_password" prometheus
    # Other apps prometheus credentials
    printf 'DAWARICH__PROMETHEUS_PASSWORD=%s\n' "$(load_token dawarich app prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h3 app prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h4-ultra app prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-2g app prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-4g app prometheus)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 app prometheus)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 app prometheus)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_PROJECT=%s\n' "$(load_token healthchecks app project-id)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_TOKEN=%s\n' "$(load_token healthchecks app api-key-readonly)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROMETHEUS_TOKEN=%s\n' "$(load_token homeassistant app homelab-viewer-api-key)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROMETHEUS_PASSWORD=%s\n' "$(load_token jellyfin app prometheus)" >>"$initial_output/app.env"
    printf 'MINIO__PROMETHEUS_TOKEN=%s\n' "$(load_token minio app prometheus-token)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h3 app prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h4-ultra app prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-2g app prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-4g app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-blackhole app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary app prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-blackhole app prometheus)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus app prometheus)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROMETHEUS_PASSWORD=%s\n' "$(load_token samba-data app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-default app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-guests app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-iot app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-matej app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-monika app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-internal app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-blackhole app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-default app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-guests app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-iot app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-matej app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-monika app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-internal app prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-blackhole app prometheus)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__PROMETHEUS_PASSWORD=%s\n' "$(load_token uptimekuma-1 app matej)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__PROMETHEUS_PASSWORD=%s\n' "$(load_token uptimekuma-2 app matej)" >>"$initial_output/app.env"
    # Proxy prometheus credentials
    printf 'ACTUALBUDGET__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token actualbudget apache prometheus)" >>"$initial_output/app.env"
    printf 'CERTBOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token certbot apache prometheus)" >>"$initial_output/app.env"
    printf 'CHANGEDETECTION__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token changedetection apache prometheus)" >>"$initial_output/app.env"
    printf 'DAWARICH__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dawarich apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_CACHE_PROXY_DOCKERHUB__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-cache-proxy-dockerhub apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h3 apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-odroid-h4-ultra apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-2g apache prometheus)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token docker-stats-raspberry-pi-4b-4g apache prometheus)" >>"$initial_output/app.env"
    printf 'DOZZLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token dozzle apache prometheus)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-1 apache prometheus)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gatus-2 apache prometheus)" >>"$initial_output/app.env"
    printf 'GOTIFY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token gotify apache prometheus)" >>"$initial_output/app.env"
    printf 'GRAFANA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token grafana apache prometheus)" >>"$initial_output/app.env"
    printf 'GROCERIES__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token groceries apache prometheus)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token healthchecks apache prometheus)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homeassistant apache prometheus)" >>"$initial_output/app.env"
    printf 'HOMEPAGE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token homepage apache prometheus)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token jellyfin apache prometheus)" >>"$initial_output/app.env"
    printf 'MINIO_CONSOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio apache prometheus)" >>"$initial_output/app.env"
    printf 'MINIO__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token minio apache prometheus)" >>"$initial_output/app.env"
    printf 'MOTIONEYE_KITCHEN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token motioneye-kitchen apache prometheus)" >>"$initial_output/app.env"
    printf 'NETALERTX__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token netalertx apache prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h3 apache prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-odroid-h4-ultra apache prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-2g apache prometheus)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token nodeexporter-raspberry-pi-4b-4g apache prometheus)" >>"$initial_output/app.env"
    printf 'NTFY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ntfy apache prometheus)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ollama-private apache prometheus)" >>"$initial_output/app.env"
    printf 'OLLAMA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token ollama apache prometheus)" >>"$initial_output/app.env"
    printf 'OMADACONTROLLER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token omadacontroller apache prometheus)" >>"$initial_output/app.env"
    printf 'OPENSPEEDTEST__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openspeedtest apache prometheus)" >>"$initial_output/app.env"
    printf 'OPENWEBUI_PRIVATE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openwebui-private apache prometheus)" >>"$initial_output/app.env"
    printf 'OPENWEBUI__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token openwebui apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-primary apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-secondary apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-1-blackhole apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-primary apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-secondary apache prometheus)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token pihole-2-blackhole apache prometheus)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token prometheus apache prometheus)" >>"$initial_output/app.env"
    printf 'RENOVATEBOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token renovatebot apache prometheus)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token samba-data apache prometheus)" >>"$initial_output/app.env"
    printf 'SMTP4DEV__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token smtp4dev apache prometheus)" >>"$initial_output/app.env"
    printf 'SPEEDTESTTRACKER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token speedtesttracker apache prometheus)" >>"$initial_output/app.env"
    printf 'TVHEADEND__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token tvheadend apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-default apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-guests apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-iot apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-matej apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-monika apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-internal apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-1-blackhole apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-default apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-guests apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-iot apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-matej apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-monika apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-internal apache prometheus)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unbound-2-blackhole apache prometheus)" >>"$initial_output/app.env"
    printf 'UNIFICONTROLLER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token unificontroller apache prometheus)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token uptimekuma-1 apache prometheus)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token uptimekuma-2 apache prometheus)" >>"$initial_output/app.env"
    printf 'VAULTWARDEN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vaultwarden apache prometheus)" >>"$initial_output/app.env"
    printf 'VIKUNJA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token vikunja apache prometheus)" >>"$initial_output/app.env"
    printf 'WIKIPEDIA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token kiwix-wikipedia apache prometheus)" >>"$initial_output/app.env"
    printf 'WIKTIONARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token kiwix-wiktionary apache prometheus)" >>"$initial_output/app.env"
    # printf 'DESKLAMP_LEFT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-left apache prometheus)" >>"$initial_output/app.env"
    # printf 'DESKLAMP_RIGHT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_token desklamp-right apache prometheus)" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    printf 'FAVICON_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/favicons.env"
    ;;
*renovatebot*)
    # App
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" app "$healthcheck_ping_key"
    renovate_token="$(load_token "$DOCKER_COMPOSE_APP_NAME" app renovate-token)" # PAT specific for each git host
    github_token="$(load_token "$DOCKER_COMPOSE_APP_NAME" app github-token)"     # GitHub PAT (even if using other git hosts)
    printf 'RENOVATE_TOKEN=%s\n' "$renovate_token" >>"$initial_output/app.env"
    printf 'GITHUB_COM_TOKEN=%s\n' "$github_token" >>"$initial_output/app.env"
    printf 'renovate-token,%s\n' "$renovate_token" >>"$initial_output/all-credentials.csv"
    printf 'github-token,%s\n' "$github_token" >>"$initial_output/all-credentials.csv"
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*samba*)
    # App
    smb_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app admin)"
    printf 'admin,%s\n' "$smb_password" >>"$initial_output/all-credentials.csv"
    printf 'SAMBA_PASSWORD=%s\n' "$smb_password" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*smtp4dev*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    printf 'ServerOptions__Users__0__Password=%s\n' "$matej_password" >>"$initial_output/app.env"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    printf 'ServerOptions__Users__1__Password=%s\n' "$homelab_viewer_password" >>"$initial_output/app.env"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-admins
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    printf 'ServerOptions__Users__2__Password=%s\n' "$homelab_test_password" >>"$initial_output/app.env"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    write_http_auth_user homelab-test "$homelab_test_password" users-admins

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    printf 'FAVICON_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/favicons.env"
    ;;
*speedtesttracker*)
    # App
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    matej_email=''
    app_key=''
    if [ "$mode" = 'dev' ]; then
        matej_email='matej@localhost'
        app_key="$(printf 'base64:' && openssl rand -base64 32)"
    else
        matej_email="matej@matejhome.com"
        app_key="$(load_token "$DOCKER_COMPOSE_APP_NAME" app app-key)"
    fi
    printf '%s,%s\n' "$matej_email" "$matej_password" >>"$initial_output/all-credentials.csv"
    printf 'APP_KEY=%s\n' "$app_key" >>"$initial_output/app.env"
    printf 'ADMIN_NAME=Matej\n' >>"$initial_output/app.env"
    printf 'ADMIN_EMAIL=%s\n' "$matej_email" >>"$initial_output/app.env"
    printf 'ADMIN_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app.env"
    printf 'MAIL_PASSWORD=\n' >>"$initial_output/app.env"
    printf 'MAIL_USERNAME=\n' >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*tvheadend*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-stream,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-stream)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*unbound*)
    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"
    matej_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/all-credentials.csv"
    homelab_viewer_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"
    homelab_test_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)"
    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*unificontroller*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-admin,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-admin)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-viewer,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)" >>"$initial_output/all-credentials.csv"

    # Database
    mongodb_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" mongodb admin)"
    printf 'mongodb,%s\n' "$mongodb_password" >>"$initial_output/all-credentials.csv"
    printf 'MONGO_PASSWORD=%s\n' "$mongodb_password" >>"$initial_output/mongodb.env"
    printf '%s' "$mongodb_password" >>"$initial_output/mongodb-password.txt"
    mongodb_root_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" mongodb admin)"
    printf 'MONGO_INITDB_ROOT_PASSWORD=%s\n' "$mongodb_root_password" >>"$initial_output/mongodb.env"
    printf 'mongodb,%s\n' "$mongodb_password" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*uptimekuma*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*vaultwarden*)
    # App
    superadmin_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app superadmin)"
    superadmin_password_hashed="$(printf '%s' "$superadmin_password" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4 | sed 's~\$~$$~g')"
    printf 'ADMIN_TOKEN=%s\n' "$superadmin_password_hashed" >>"$initial_output/app.env"
    printf 'superadmin,%s\n' "$superadmin_password" >>"$initial_output/all-credentials.csv"
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-viewer,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-viewer)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*vikunja*)
    # App
    printf 'matej,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app matej)" >>"$initial_output/all-credentials.csv"
    printf 'homelab-test,%s\n' "$(load_password "$DOCKER_COMPOSE_APP_NAME" app homelab-test)" >>"$initial_output/all-credentials.csv"
    jwt_secret="$(load_token "$DOCKER_COMPOSE_APP_NAME" app jwt-secret)"
    printf 'jwt-secret,%s\n' "$jwt_secret" >>"$initial_output/all-credentials.csv"
    printf 'VIKUNJA_SERVICE_JWTSECRET=%s\n' "$jwt_secret" >>"$initial_output/app.env"
    prometheus_password="$(load_password "$DOCKER_COMPOSE_APP_NAME" app prometheus)"
    printf 'prometheus,%s\n' "$prometheus_password" >>"$initial_output/all-credentials.csv"
    printf 'VIKUNJA_METRICS_PASSWORD=%s\n' "$prometheus_password" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$DOCKER_COMPOSE_APP_NAME"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$DOCKER_COMPOSE_APP_NAME" certificator "$healthcheck_ping_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*)
    printf 'Unknown app directory name: %s\n' "$app_dir" >&2
    exit 1
    ;;
esac

# TODO: Switch to 0400 permissions eventually after unifying container users
find "$initial_output" -type f -exec chmod 0444 {} \;

output='app-secrets'
if [ -e "$output" ]; then
    rm -rf "$output"
fi
cp -R "$initial_output" "$output"
# mkdir "$output"
# find "$initial_output" -mindepth 1 -maxdepth 1 -exec sh -c 'mv "$initial_output/$(basename "$1")" "$output/$(basename "$1")"' - \;

# Cleanup
rm -rf "$tmpdir"
