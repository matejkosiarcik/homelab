#!/bin/sh
set -euf

helper_script_dir="$(cd "$(dirname "$0")" >/dev/null && pwd)"
git_root_dir="$(git rev-parse --show-toplevel)"

LANG=en_US.UTF-8
export LANG
LANGUAGE=en_US.UTF-8
export LANGUAGE
LC_ALL=en_US.UTF-8
export LC_ALL
LC_CTYPE=en_US.UTF-8
export LC_CTYPE

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
    *)
        printf 'Unknown argument %s\n' "$1"
        exit 1
        ;;
    esac
done

initial_output="$(mktemp -d)"
printf 'secret-name,secret-value\n' >"$initial_output/.secrets.csv"

app_dir_path="$PWD"
app_shortname="$(basename "$app_dir_path" | sed -E 's~^\.~~')"

app_type="$(yq --raw-output .app.type "$app_dir_path/config/config.yml")"
if [ "$app_type" = '' ] || [ "$app_type" = 'null' ] || [ "$app_type" = 'undefined' ]; then
    app_type="$app_shortname"
fi

app_fullname="$(yq --raw-output .app.fullname "$app_dir_path/config/config.yml")"
if [ "$app_fullname" = '' ] || [ "$app_fullname" = 'null' ] || [ "$app_fullname" = 'undefined' ]; then
    app_fullname="$app_shortname"
fi
app_fullname_key="$(printf '%s' "$app_fullname" | tr '-' '_')"

domain="$(yq --raw-output .network.domain "$app_dir_path/config/config.yml")"
if [ "$domain" = '' ] || [ "$domain" = 'null' ] || [ "$domain" = 'undefined' ]; then
    domain="$app_fullname.matejhome.com"
fi

tmpdir="$(mktemp -d)"

# Set SOPS decryption key file
SOPS_AGE_KEY_FILE="$git_root_dir/secrets/age-key.txt"
export SOPS_AGE_KEY_FILE
if [ ! -e "$SOPS_AGE_KEY_FILE" ]; then
    printf 'SOPS_AGE_KEY_FILE not found\n' >&2
    exit 1
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

load_secret() {
    # $1 - yq query
    # $2 - behaviour for dev environment

    if [ "$#" -lt 2 ]; then
        printf 'Missing arguments for load_secret() function, got: %s\n' "$#" >&2
        exit 1
    fi

    main_secret="$(sops --decrypt --config "$git_root_dir/secrets/.sops.yaml" "$git_root_dir/secrets/secrets.enc.yml" | yq "$1")"
    if [ "$main_secret" = '' ] || [ "$main_secret" = 'null' ] || [ "$main_secret" = 'undefined' ]; then
        printf 'Could not load secret "%s"\n' "$1" >&2
        exit 1
    fi

    if [ "$mode" = 'dev' ] && [ "$2" = 'dev=empty' ]; then
        printf '\n'
        return
    fi

    if [ "$mode" = 'dev' ] && [ "$2" = 'dev=default' ]; then
        printf 'Password123.\n'
        return
    fi

    if [ "$mode" = 'dev' ] && printf '%s' "$2" | grep -E '^dev=value=.+$' >/dev/null 2>&1; then
        fallback_secret="$(printf '%s' "$2" | sed -E 's~^dev=value=~~')"
        printf '%s\n' "$fallback_secret"
        return
    fi

    printf '%s\n' "$main_secret"
}

healthchecks_ping_key="$(load_secret '.healthchecks.app.ping_key' dev=empty)"

write_healthcheck_url() {
    # $1 - app name
    # $2 - container name

    if [ "$healthchecks_ping_key" = '' ]; then
        healthcheck_url=''
    else
        healthcheck_url="https://healthchecks.matejhome.com/ping/$healthchecks_ping_key/$1-$2"
    fi
    printf 'HOMELAB_HEALTHCHECK_URL=%s\n' "$healthcheck_url" >>"$initial_output/$2.env"
    printf 'healthchecks-url-%s,%s\n' "$2" "$healthcheck_url" >>"$initial_output/.secrets.csv"
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
    proxy_status_password="$(load_secret ".$1.apache.status_user" dev=default)"
    write_http_auth_user proxy-status "$proxy_status_password" proxy-status
    printf 'PROXY_STATUS_PASSWORD=%s\n' "$proxy_status_password" >>"$initial_output/apache-prometheus-exporter.env"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$initial_output/.secrets.csv"
    proxy_prometheus_password="$(load_secret ".$1.apache.prometheus_user" dev=default)"
    write_http_auth_user proxy-prometheus "$proxy_prometheus_password" proxy-prometheus
    printf 'proxy-prometheus,%s\n' "$proxy_prometheus_password" >>"$initial_output/.secrets.csv"
}

write_certificator_users() {
    # No arguments
    certbot_certificator_password="$(load_secret '.certbot.app.certificator_user' dev=real)"
    printf 'CERTBOT_CERTIFICATOR_PASSWORD=%s\n' "$certbot_certificator_password" >>"$initial_output/certificator.env"
}

case "$app_type" in
actualbudget)
    # App
    printf 'admin,%s\n' "$(load_secret ".$app_fullname_key.app.admin_user" dev=default)" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
adventurelog)
    # App
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'monika,%s\n' "$(load_secret ".$app_fullname_key.app.monika_user" dev=default)" >>"$initial_output/.secrets.csv"
    django_admin_password="$(load_secret ".$app_fullname_key.app.django_admin_user" dev=default)"
    printf 'DJANGO_ADMIN_PASSWORD=%s\n' "$django_admin_password" >>"$initial_output/app-backend.env"
    printf 'django-admin,%s\n' "$django_admin_password" >>"$initial_output/.secrets.csv"
    secret_key="$(load_secret ".$app_fullname_key.app.secret_key" "dev=value=$(openssl rand -hex 32)")"
    printf 'SECRET_KEY=%s\n' "$secret_key" >>"$initial_output/app-backend.env"
    printf 'secret-key,%s\n' "$secret_key" >>"$initial_output/.secrets.csv"

    # Postgis
    postgres_password="$(load_secret ".$app_fullname_key.postgis.user" dev=default)"
    printf 'PGPASSWORD=%s\n' "$postgres_password" >>"$initial_output/app-backend.env"
    printf 'POSTGRES_PASSWORD=%s\n' "$postgres_password" >>"$initial_output/postgis.env"
    printf 'postgis,%s\n' "$postgres_password" >>"$initial_output/.secrets.csv"
    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgis.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgis.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
changedetection)
    # App
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
certbot)
    # App
    certbot_matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    write_http_auth_user matej "$certbot_matej_password" proxy-prometheus
    write_http_auth_user matej "$certbot_matej_password" users-viewers
    write_http_auth_user matej "$certbot_matej_password" users-admins
    printf 'matej,%s\n' "$certbot_matej_password" >>"$initial_output/.secrets.csv"
    certbot_certificator_password="$(load_secret ".$app_fullname_key.app.certificator_user" dev=default)"
    write_http_auth_user certificator "$certbot_certificator_password" users-viewers
    printf 'certificator,%s\n' "$certbot_certificator_password" >>"$initial_output/.secrets.csv"
    certbot_public_email="$(load_secret ".$app_fullname_key.websupport.public_email" dev=empty)"
    printf 'CERTBOT_PUBLIC_EMAIL=%s\n' "$certbot_public_email" >>"$initial_output/app.env"
    websupport_api_key="$(load_secret ".$app_fullname_key.websupport.api_key" dev=empty)"
    printf 'WEBSUPPORT_API_KEY=%s\n' "$websupport_api_key" >>"$initial_output/app.env"
    websupport_api_secret="$(load_secret ".$app_fullname_key.websupport.api_secret" dev=empty)"
    printf 'WEBSUPPORT_API_SECRET=%s\n' "$websupport_api_secret" >>"$initial_output/app.env"
    websupport_service_id="$(load_secret ".$app_fullname_key.websupport.service_id" dev=empty)"
    printf 'WEBSUPPORT_SERVICE_ID=%s\n' "$websupport_service_id" >>"$initial_output/app.env"
    write_healthcheck_url "$app_fullname_key" app

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
dawarich)
    # App
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'api-key,%s\n' "$(load_secret ".$app_fullname_key.app.api_key" dev=empty)" >>"$initial_output/.secrets.csv"

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Decryptor
    decryptor_key="$(load_secret ".$app_fullname_key.decryptor.secret_key" "dev=value=$(openssl rand -hex 16)")"
    printf 'WEBUI_SECRET_KEY=%s\n' "$decryptor_key" >>"$initial_output/app.env"
    printf 'SECRET_KEY=%s\n' "$decryptor_key" >>"$initial_output/decryptor.env"
    printf 'secret-key,%s\n' "$decryptor_key" >>"$initial_output/.secrets.csv"

    # Postgis
    postgis_password="$(load_secret ".$app_fullname_key.postgis.user" dev=default)"
    printf 'DATABASE_PASSWORD=%s\n' "$postgis_password" >>"$initial_output/app.env"
    printf 'POSTGRES_PASSWORD=%s\n' "$postgis_password" >>"$initial_output/postgis.env"
    printf 'postgis,%s\n' "$postgis_password" >>"$initial_output/.secrets.csv"
    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgis.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgis.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # Redis
    redis_password="$(load_secret ".$app_fullname_key.redis.user" dev=default)"
    printf 'REDIS_PASSWORD=%s\n' "$redis_password" >>"$initial_output/redis.env"
    printf 'REDIS_PASSWORD=%s\n' "$redis_password" >>"$initial_output/app.env"
    printf 'redis,%s\n' "$redis_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
docker-cache)
    # App
    http_secret="$(load_secret ".$app_fullname_key.app.http_secret" "dev=value=$(openssl rand -hex 16)")"
    printf 'REGISTRY_HTTP_SECRET=%s\n' "$http_secret" >>"$initial_output/app.env"
    printf 'REGISTRY_PROXY_USERNAME=\n' >>"$initial_output/app.env"
    printf 'REGISTRY_PROXY_PASSWORD=\n' >>"$initial_output/app.env"

    # Redis
    redis_password="$(load_secret ".$app_fullname_key.redis.user" dev=default)"
    printf 'REDIS_PASSWORD=%s\n' "$redis_password" >>"$initial_output/redis.env"
    printf 'REDIS_PASSWORD=%s\n' "$redis_password" >>"$initial_output/app.env"
    printf 'redis,%s\n' "$redis_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
docker-stats)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
donetick)
    # App
    jwt_secret="$(load_secret ".$app_fullname_key.app.jwt_secret" "dev=value=$(openssl rand -base64 32 | base64)")"
    printf 'DT_JWT_SECRET=%s\n' "$jwt_secret" >>"$initial_output/app.env"
    printf 'jwt-secret,%s\n' "$jwt_secret" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
dozzle)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    hash_password_bcrypt "$matej_password" >"$tmpdir/matej-password-encrypted.txt"
    printf 'users:\n' >>"$initial_output/dozzle-users.yml"
    printf '    matej:\n' >>"$initial_output/dozzle-users.yml"
    printf '        email: matej@%s\n' "$domain" >>"$initial_output/dozzle-users.yml"
    printf '        name: matej\n' >>"$initial_output/dozzle-users.yml"
    printf '        password: %s\n' "$(cat "$tmpdir/matej-password-encrypted.txt")" >>"$initial_output/dozzle-users.yml"

    # Dozzle-agent key
    openssl genpkey -algorithm RSA -out "$tmpdir/key.pem" -pkeyopt rsa_keygen_bits:2048
    openssl req -new -key "$tmpdir/key.pem" -out "$tmpdir/request.csr" -subj "/C=SK/ST=Slovakia/L=Bratislava/O=Homelab"
    openssl x509 -req -in "$tmpdir/request.csr" -signkey "$tmpdir/key.pem" -out "$tmpdir/cert.pem" -days 3650
    load_secret ".$app_fullname_key.app.key" "dev=value=$(base64 <"$tmpdir/key.pem")" | base64 --decode >"$initial_output/dozzle-key.pem"
    load_secret ".$app_fullname_key.app.cert" "dev=value=$(base64 <"$tmpdir/cert.pem")" | base64 --decode >"$initial_output/dozzle-cert.pem"
    rm -f "$tmpdir/key.pem" "$tmpdir/request.csr" "$tmpdir/cert.pem"

    # Apache
    write_default_proxy_users dozzle

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
dozzle-agent)
    # App
    openssl genpkey -algorithm RSA -out "$tmpdir/key.pem" -pkeyopt rsa_keygen_bits:2048
    openssl req -new -key "$tmpdir/key.pem" -out "$tmpdir/request.csr" -subj "/C=SK/ST=Slovakia/L=Bratislava/O=Homelab"
    openssl x509 -req -in "$tmpdir/request.csr" -signkey "$tmpdir/key.pem" -out "$tmpdir/cert.pem" -days 3650
    load_secret ".dozzle.app.key" "dev=value=$(base64 <"$tmpdir/key.pem")" | base64 --decode >"$initial_output/dozzle-key.pem"
    load_secret ".dozzle.app.cert" "dev=value=$(base64 <"$tmpdir/cert.pem")" | base64 --decode >"$initial_output/dozzle-cert.pem"
    rm -f "$tmpdir/key.pem" "$tmpdir/request.csr" "$tmpdir/cert.pem"
    ;;
gatus)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$matej_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Main credentials
    printf 'CERTBOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.certbot.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.docker-stats-odroid-h3.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.docker-stats-odroid-h4-ultra.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.docker-stats-raspberry-pi-4b-2g.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.docker-stats-raspberry-pi-4b-4g.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_1__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.gatus-1.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_2__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.gatus-2.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'GOTIFY__TOKEN=%s\n' "$(load_secret '.gotify.app.gatus-token' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.homepage.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'LIBRETRANSLATE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.libretranslate.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'MOTIONEYE_KITCHEN__HOMELAB_STREAM_PASSWORD=%s\n' "$(load_secret '.motioneye-kitchen.app.homelab-stream' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.nodeexporter-odroid-h3.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.nodeexporter-odroid-h4-ultra.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.nodeexporter-raspberry-pi-4b-2g.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.nodeexporter-raspberry-pi-4b-4g.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'NTFY__TOKEN=%s\n' "$(load_secret '.ntfy.app.homelab-publisher-token' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.ollama.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.ollama-private.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.prometheus.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'RENOVATEBOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.renovatebot.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'SMTP4DEV__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.smtp4dev.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-1-default.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-1-guests.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-1-iot.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-1-matej.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-1-monika.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-1-internal.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-1-blackhole.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-2-default.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-2-guests.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-2-iot.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-2-matej.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-2-monika.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-2-internal.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound-2-blackhole.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__MATEJ_PASSWORD=%s\n' "$(load_secret '.uptimekuma-1.app.matej' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__MATEJ_PASSWORD=%s\n' "$(load_secret '.uptimekuma-2.app.matej' dev=real)" >>"$initial_output/app.env"
    printf 'WIKIPEDIA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.kiwix-wikipedia.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    printf 'WIKTIONARY__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.kiwix-wiktionary.app.homelab_viewer' dev=real)" >>"$initial_output/app.env"
    # Prometheus metrics credentials
    printf 'ACTUALBUDGET__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.actualbudget.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'CERTBOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.certbot.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'CHANGEDETECTION__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.changedetection.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'DAWARICH__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.dawarich.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_CACHE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker-cache.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker-stats-odroid-h3.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker-stats-odroid-h4-ultra.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker-stats-raspberry-pi-4b-2g.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker-stats-raspberry-pi-4b-4g.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'DONETICK__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.donetick.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'DOZZLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.dozzle.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gatus-1.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gatus-2.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'GOTIFY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gotify.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'GRAFANA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.grafana.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'GROCERIES__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.groceries.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.healthchecks.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_PROJECT=%s\n' "$(load_secret healthchecks app project-id)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_TOKEN=%s\n' "$(load_secret healthchecks app api-key-readonly)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.homeassistant.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROMETHEUS_TOKEN=%s\n' "$(load_secret '.homeassistant.app.homelab-viewer-api-key' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.homepage.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.jellyfin.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'KOFFAN__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.koffan.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'LIBRETRANSLATE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.libretranslate.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.minio.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO__PROMETHEUS_TOKEN=%s\n' "$(load_secret '.minio.app.prometheus-token' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO_CONSOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.minio-console.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'MOTIONEYE_KITCHEN__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.motioneye-kitchen.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter-odroid-h3.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter-odroid-h4-ultra.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter-raspberry-pi-4b-2g.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter-raspberry-pi-4b-4g.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NTFY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ntfy.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ollama.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ollama-private.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OMADACONTROLLER__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.omadacontroller.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OPENSPEEDTEST__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.openspeedtest.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OPENWEBUI__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.openwebui.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OPENWEBUI_PRIVATE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.openwebui-private.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-1-blackhole.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-1-primary.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-1-secondary.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-2-blackhole.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-2-primary.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-2-secondary.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PLANKA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.planka.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.prometheus.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'RENOVATEBOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.renovatebot.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'REPORTPORTAL__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.reportportal.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.samba-data.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'SMTP4DEV__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.smtp4dev.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'SPEEDTESTTRACKER__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.speedtesttracker.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'TVHEADEND__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.tvheadend.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-1-blackhole.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-1-default.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-1-guests.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-1-internal.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-1-iot.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-1-matej.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-1-monika.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-2-blackhole.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-2-default.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-2-guests.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-2-internal.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-2-iot.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-2-matej.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound-2-monika.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNIFICONTROLLER__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unificontroller.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.uptimekuma-1.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.uptimekuma-2.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'VAULTWARDEN__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.vaultwarden.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'WIKIPEDIA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.kiwix-wikipedia.general.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'WIKTIONARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.kiwix-wiktionary.general.prometheus' dev=real)" >>"$initial_output/app.env"
    # printf 'DESKLAMP_LEFT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.desklamp-left.general.prometheus' dev=real)" >>"$initial_output/app.env"
    # printf 'DESKLAMP_RIGHT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.desklamp-right.general.prometheus' dev=real)" >>"$initial_output/app.env"
    # printf 'NETALERTX__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.netalertx.general.prometheus' dev=real)" >>"$initial_output/app.env"
    # printf 'VIKUNJA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.vikunja.general.prometheus' dev=real)" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
git-cache)
    postgres_password="$(load_secret ".$app_fullname_key.postgres.user" dev=default)"

    # App
    printf 'PGPASSWORD=%s\n' "$postgres_password" >>"$initial_output/app.env"

    # Postgres
    printf 'POSTGRES_PASSWORD=%s\n' "$postgres_password" >>"$initial_output/postgres.env"
    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgres.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgres.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # Redis
    redis_password="$(load_secret ".$app_fullname_key.redis.user" dev=default)"
    printf 'REDIS_PASSWORD=%s\n' "$redis_password" >>"$initial_output/redis.env"
    printf 'REDIS_PASSWORD=%s\n' "$redis_password" >>"$initial_output/app.env"
    printf 'redis,%s\n' "$redis_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
gotify)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'GOTIFY_DEFAULTUSER_PASS=%s\n' "$matej_password" >>"$initial_output/app.env"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
grafana)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'GF_SECURITY_ADMIN_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app.env"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
groceries)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    monika_password="$(load_secret ".$app_fullname_key.app.monika_user" dev=default)"
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/.secrets.csv"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'SMTP_PASSWORD=\n' >>"$initial_output/app.env" # Placeholder

    # CouchDB
    couchdb_password="$(load_secret ".$app_fullname_key.couchdb.user" dev=default)"
    printf 'COUCHDB_ADMIN_PASSWORD=%s\n' "$couchdb_password" >>"$initial_output/app.env"
    printf 'COUCHDB_PASSWORD=%s\n' "$couchdb_password" >>"$initial_output/couchdb.env"
    printf 'couchdb,%s\n' "$couchdb_password" >>"$initial_output/.secrets.csv"
    hmac_key="$(load_secret ".$app_fullname_key.couchdb.hmac_key" dev=default)"
    printf 'COUCHDB_HMAC_KEY=%s\n' "$hmac_key" >>"$initial_output/app.env"
    printf 'HMAC_KEY=%s\n' "$hmac_key" >>"$initial_output/couchdb.env"
    printf 'couchdb-hmac,%s\n' "$hmac_key" >>"$initial_output/.secrets.csv"
    uuid="$(load_secret ".$app_fullname_key.couchdb.uuid" "dev=value=$(uuidgen)")"
    printf 'UUID=%s\n' "$uuid" >>"$initial_output/couchdb.env"
    printf 'couchdb-uuid,%s\n' "$uuid" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
healthchecks)
    # App
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)" >>"$initial_output/.secrets.csv"
    secret_key="$(load_secret ".$app_fullname_key.app.secret_key" dev=default)"
    printf 'SECRET_KEY=%s\n' "$secret_key" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
homeassistant)
    # App
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'monika,%s\n' "$(load_secret ".$app_fullname_key.app.monika" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-admin,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_admin_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
homepage)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'HOMEPAGE_VAR__CHANGEDETECTION__APIKEY=%s\n' "$(load_secret '.changedetection.app.api_key' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__GATUS_1__PASSWORD=%s\n' "$(load_secret '.gatus-1.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__GATUS_2__PASSWORD=%s\n' "$(load_secret '.gatus-2.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__GRAFANA__PASSWORD=%s\n' "$(load_secret '.grafana.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__HEALTHCHECKS__APIKEY=%s\n' "$(load_secret '.healthchecks.app.api_key_readonly' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__HOMEASSISTANT__APIKEY=%s\n' "$(load_secret '.homeassistant.app.homelab_viewer_api_key' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__JELLYFIN__APIKEY=%s\n' "$(load_secret '.jellyfin.app.homelab_api_key' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__MOTIONEYE_KITCHEN__HOMELAB_STREAM_PASSWORD=%s\n' "$(load_secret '.motioneye_kitchen.app.homelab_stream_user' dev=real)" >>"$initial_output/app.env"
    # TODO: Enable NetAlertX integration
    # printf 'HOMEPAGE_VAR_NETALERTX_APIKEY=%s\n' "$(load_secret '.netalertx.app.api_key' dev=real)" "$initial_output/app.env"
    printf 'HOMEPAGE_VAR__OMADACONTROLLER__PASSWORD=%s\n' "$(load_secret 'omadacontroller.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_1_PRIMARY__PASSWORD=%s\n' "$(load_secret 'pihole-1-primary.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_1_SECONDARY__PASSWORD=%s\n' "$(load_secret 'pihole-1-secondary.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_1_BLACKHOLE__PASSWORD=%s\n' "$(load_secret 'pihole-1-blackhole.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_2_PRIMARY__PASSWORD=%s\n' "$(load_secret 'pihole-2-primary.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_2_SECONDARY__PASSWORD=%s\n' "$(load_secret 'pihole-2-secondary.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_2_BLACKHOLE__PASSWORD=%s\n' "$(load_secret 'pihole-2-blackhole.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PROMETHEUS__PASSWORD=%s\n' "$(load_secret 'prometheus.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__SPEEDTESTTRACKER__APIKEY=%s\n' "$(load_secret 'speedtesttracker.app.api_key_readonly' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__UNIFICONTROLLER__PASSWORD=%s\n' "$(load_secret 'unificontroller.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__VIKUNJA__APIKEY=%s\n' "$(load_secret 'vikunja.app.api_key_readonly' dev=real)" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    printf 'FAVICON_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/favicons.env"

    # Widgets
    printf 'PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.prometheus.app.homelab_viewer_user' dev=real)" >>"$initial_output/widgets.env"
    printf 'SMTP4DEV_PASSWORD=%s\n' "$(load_secret '.smtp4dev.app.homelab_viewer_user' dev=real)" >>"$initial_output/widgets.env"
    ;;
jellyfin)
    # App
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'monika,%s\n' "$(load_secret ".$app_fullname_key.app.monika_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-admin,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_admin_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
kiwix)
    # Apache
    write_default_proxy_users "$app_fullname_key"
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    monika_password="$(load_secret ".$app_fullname_key.app.monika_user" dev=default)"
    write_http_auth_user monika "$monika_password" users-viewers
    write_http_auth_user monika "$monika_password" users-admins
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/.secrets.csv"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
koffan)
    # App
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"
    printf 'APP_PASSWORD=%s\n' "$admin_password" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
libretranslate)
    # Apache
    write_default_proxy_users "$app_fullname_key"

    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    monika_password="$(load_secret ".$app_fullname_key.app.monika_user" dev=default)"
    write_http_auth_user monika "$monika_password" users-viewers
    write_http_auth_user monika "$monika_password" users-admins
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/.secrets.csv"

    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
minio)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_writer_password="$(load_secret ".$app_fullname_key.app.homelab_writer_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-writer,%s\n' "$homelab_writer_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'MINIO_ROOT_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app.env"

    # Setup
    printf 'MINIO_MATEJ_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app-setup.env"
    printf 'MINIO_HOMELAB_WRITER_PASSWORD=%s\n' "$homelab_writer_password" >>"$initial_output/app-setup.env"
    printf 'MINIO_HOMELAB_VIEWER_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/app-setup.env"
    printf 'MINIO_HOMELAB_TEST_PASSWORD=%s\n' "$homelab_test_password" >>"$initial_output/app-setup.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
motioneye)
    # App
    printf 'admin,%s\n' "$(load_secret ".$app_fullname_key.app.admin_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'stream,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_stream_user" dev=default)" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
nodeexporter)
    # Apache
    write_default_proxy_users "$app_fullname_key"

    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
npm-cache)
    # Redis
    redis_password="$(load_secret ".$app_fullname_key.redis.user" dev=default)"
    printf 'REDIS_PASSWORD=%s\n' "$redis_password" >>"$initial_output/redis.env"
    printf 'REDIS_PASSWORD=%s\n' "$redis_password" >>"$initial_output/app.env"
    printf 'redis,%s\n' "$redis_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
ntfy)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'NTFY_PASSWORD_MATEJ=%s\n' "$matej_password" >>"$initial_output/app.env"
    homelab_publisher_password="$(load_secret ".$app_fullname_key.app.homelab_publisher_user" dev=default)"
    printf 'homelab-publisher,%s\n' "$homelab_publisher_password" >>"$initial_output/.secrets.csv"
    printf 'NTFY_PASSWORD_HOMELAB_PUBLISHER=%s\n' "$homelab_publisher_password" >>"$initial_output/app.env"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    printf 'NTFY_PASSWORD_HOMELAB_VIEWER=%s\n' "$homelab_viewer_password" >>"$initial_output/app.env"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'NTFY_PASSWORD_HOMELAB_TEST=%s\n' "$homelab_test_password" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
ollama)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    openwebui_password="$(load_secret ".$app_fullname_key.app.openwebui_user" dev=default)"
    write_http_auth_user openwebui "$openwebui_password" users-viewers
    write_http_auth_user openwebui "$openwebui_password" users-admins
    printf 'openwebui,%s\n' "$openwebui_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
omadacontroller)
    # App
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-admin,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_admin_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
openspeedtest)
    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
openwebui)
    # App
    ollama_openwebui_password="$(load_secret '.ollama.app.openwebui_user' dev=real)"
    printf 'OLLAMA_BASE_URL=%s\n' "https://openwebui:$ollama_openwebui_password@$DOCKER_COMPOSE_OLLAMA_UPSTREAM_DOMAIN" >>"$initial_output/app.env"
    secret_key="$(load_secret ".$app_fullname_key.app.secret_key" "dev=value=$(openssl rand -hex 16)")"
    printf 'WEBUI_SECRET_KEY=%s\n' "$secret_key" >>"$initial_output/app.env"
    printf 'secret-key,%s\n' "$secret_key" >>"$initial_output/.secrets.csv"
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
pihole)
    # App
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"
    printf 'FTLCONF_webserver_api_password=%s\n' "$admin_password" >>"$initial_output/app.env"

    # Prometheus exporter
    printf 'PIHOLE_PASSWORD=%s\n' "$admin_password" >>"$initial_output/app-prometheus-exporter.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
planka)
    # App
    secret_key="$(load_secret ".$app_fullname.app.secret_key" "dev=value=$(openssl rand -hex 64)")"
    printf 'SECRET_KEY=%s\n' "$secret_key" >>"$initial_output/app.env"
    printf 'secret-key,%s\n' "$secret_key" >>"$initial_output/.secrets.csv"
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    if [ "$mode" = 'dev' ]; then
        matej_email='matej@localhost'
    else
        matej_email='matej@matejhome.com'
    fi
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'DEFAULT_ADMIN_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app.env"
    printf 'DEFAULT_ADMIN_EMAIL=%s\n' "$matej_email" >>"$initial_output/app.env"
    printf 'DEFAULT_ADMIN_USERNAME=%s\n' "$(printf '%s' "$matej_email" | cut -d '@' -f 1)" >>"$initial_output/app.env"
    printf 'DEFAULT_ADMIN_NAME=%s\n' "$(printf '%s' "$matej_email" | cut -d '@' -f 1 | awk '{print toupper(substr($0,0,1))substr($0,2)}')" >>"$initial_output/app.env"

    # Postgres
    postgres_password="$(load_secret ".$app_fullname_key.postgres.user" dev=default)"
    printf 'DATABASE_PASSWORD=%s\n' "$postgres_password" >>"$initial_output/app.env"
    printf 'POSTGRES_PASSWORD=%s\n' "$postgres_password" >>"$initial_output/postgres.env"
    printf 'postgres,%s\n' "$postgres_password" >>"$initial_output/.secrets.csv"
    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgres.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgres.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
prometheus)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'PROMETHEUS__MATEJ_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$matej_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins

    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$homelab_viewer_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/app.env"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers

    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'PROMETHEUS__HOMELAB_TEST_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$homelab_test_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD_ENCRYPTED=%s\n' "$(hash_password_bcrypt "$prometheus_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user prometheus "$matej_password" prometheus

    # Prometheus metrics credentials
    printf 'ACTUALBUDGET__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.actualbudget.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'ADVENTURELOG__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.adventurelog.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'CERTBOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.certbot.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'CHANGEDETECTION__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.changedetection.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DAWARICH__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.dawarich.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_CACHE_DOCKERHUB__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_cache.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_odroid_h3.apache.prometheus_user_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_odroid_h4_ultra.apache.prometheus_user_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.apache.prometheus_user_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.apache.prometheus_user_user' dev=real)" >>"$initial_output/app.env"
    printf 'DONETICK__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.donetick.apache.prometheus_user_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOZZLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.dozzle.apache.prometheus_user_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gatus_1.apache.prometheus_user_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gatus_2.apache.prometheus_user_user' dev=real)" >>"$initial_output/app.env"
    printf 'GIT_CACHE_GITHUB__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.git-cache-github.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GOTIFY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gotify.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GRAFANA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.grafana.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GROCERIES__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.groceries.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.healthchecks.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_PROJECT=%s\n' "$(load_secret '.healthchecks.app.project_id' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_TOKEN=%s\n' "$(load_secret '.healthchecks.app.api_key_readonly' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.homeassistant.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROMETHEUS_TOKEN=%s\n' "$(load_secret '.homeassistant.app.homelab_viewer_api_key' dev=real) dev=real" >>"$initial_output/app.env"
    printf 'HOMEPAGE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.homepage.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.jellyfin.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'KIWIX_WIKIPEDIA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.kiwix_wikipedia.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'KIWIX_WIKTIONARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.kiwix_wiktionary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'KOFFAN__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.koffan.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'LIBRETRANSLATE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.libretranslate.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.minio.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO__PROMETHEUS_TOKEN=%s\n' "$(load_secret '.minio.app.prometheus-token' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO_CONSOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.minio.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MOTIONEYE_KITCHEN__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.motioneye_kitchen.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NETALERTX__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.netalertx.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter-odroid-h3.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter-odroid-h4-ultra.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter-raspberry-pi-4b-2g.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter-raspberry-pi-4b-4g.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NPM_CACHE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.npm-cache.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'NTFY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ntfy.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ollama.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ollama-private.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OMADACONTROLLER__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.omadacontroller.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OPENSPEEDTEST__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.openspeedtest.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OPENWEBUI__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.openwebui.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'OPENWEBUI_PRIVATE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.openwebui-private.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-1-blackhole.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-1-primary.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-1-secondary.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-2-blackhole.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-2-primary.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole-2-secondary.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PLANKA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.planka.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.prometheus.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'RENOVATEBOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.renovatebot.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'REPORTPORTAL__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.reportportal.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.samba-data.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'SMTP4DEV__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.smtp4dev.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'SPEEDTESTTRACKER__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.speedtesttracker.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'TVHEADEND__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.tvheadend.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_blackhole.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_default.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_guests.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_internal.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_iot.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_matej.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_monika.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_blackhole.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_default.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_guests.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_internal.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_iot.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_matej.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_monika.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UNIFICONTROLLER__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unificontroller.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__MATEJ_PASSWORD=%s\n' "$(load_secret '.uptimekuma-1.app.matej_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.uptimekuma-1.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__MATEJ_PASSWORD=%s\n' "$(load_secret '.uptimekuma-2.app.matej' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.uptimekuma-2.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'VAULTWARDEN__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.vaultwarden.apache.prometheus' dev=real)" >>"$initial_output/app.env"
    printf 'VIKUNJA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.vikunja.apache.prometheus' dev=real)" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    printf 'FAVICON_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/favicons.env"
    ;;
renovatebot)
    # App
    write_healthcheck_url "$app_fullname_key" app
    renovate_token="$(load_secret ".$app_fullname.app.renovate_token" dev=real)" # PAT specific for each git host
    github_token="$(load_secret ".$app_fullname.app.github_token" dev=real)"     # GitHub PAT (even if using other git hosts)
    printf 'RENOVATE_TOKEN=%s\n' "$renovate_token" >>"$initial_output/app.env"
    printf 'GITHUB_COM_TOKEN=%s\n' "$github_token" >>"$initial_output/app.env"
    printf 'renovate-token,%s\n' "$renovate_token" >>"$initial_output/.secrets.csv"
    printf 'github-token,%s\n' "$github_token" >>"$initial_output/.secrets.csv"
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
reportportal)
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"
    postgres_password="$(load_secret ".$app_fullname_key.postgres.user" dev=default)"
    rabbitmq_password="$(load_secret ".$app_fullname_key.rabbitmq.user" dev=default)"

    # App
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"
    printf 'RP_INITIAL_ADMIN_PASSWORD=%s\n' "$admin_password" >>"$initial_output/app-uat.env"
    printf 'RP_DB_PASS=%s\n' "$postgres_password" >>"$initial_output/app-api.env"
    printf 'RP_AMQP_PASS=%s\n' "$rabbitmq_password" >>"$initial_output/app-api.env"
    printf 'RP_AMQP_APIPASS=%s\n' "$rabbitmq_password" >>"$initial_output/app-api.env"
    printf 'RP_DB_PASS=%s\n' "$postgres_password" >>"$initial_output/app-uat.env"
    printf 'RP_AMQP_PASS=%s\n' "$rabbitmq_password" >>"$initial_output/app-uat.env"
    printf 'RP_AMQP_APIPASS=%s\n' "$rabbitmq_password" >>"$initial_output/app-uat.env"
    printf 'RP_DB_PASS=%s\n' "$postgres_password" >>"$initial_output/app-jobs.env"
    printf 'RP_AMQP_PASS=%s\n' "$rabbitmq_password" >>"$initial_output/app-jobs.env"
    printf 'RP_AMQP_APIPASS=%s\n' "$rabbitmq_password" >>"$initial_output/app-jobs.env"
    printf 'POSTGRES_PASSWORD=%s\n' "$postgres_password" >>"$initial_output/app-migrations.env"
    printf 'AMQP_URL=%s%s%s%s\n' 'amqp://' 'rabbitmq:' "$rabbitmq_password" '@rabbitmq:5672' >>"$initial_output/app-analyzer.env"

    # Postgres
    printf 'postgres,%s\n' "$postgres_password" >>"$initial_output/.secrets.csv"
    printf 'POSTGRES_PASSWORD=%s\n' "$postgres_password" >>"$initial_output/postgres.env"
    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgres.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgres.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # RabbitMQ
    printf 'rabbitmq,%s\n' "$rabbitmq_password" >>"$initial_output/.secrets.csv"
    printf 'RABBITMQ_DEFAULT_PASS=%s\n' "$rabbitmq_password" >>"$initial_output/rabbitmq.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
samba)
    # App
    smb_password="$(load_secret ".$app_fullname_key.app.user" dev=default)"
    printf 'admin,%s\n' "$smb_password" >>"$initial_output/.secrets.csv"
    printf 'SAMBA_PASSWORD=%s\n' "$smb_password" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"
    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
smtp4dev)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    printf 'ServerOptions__Users__0__Password=%s\n' "$matej_password" >>"$initial_output/app.env"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    printf 'ServerOptions__Users__1__Password=%s\n' "$homelab_viewer_password" >>"$initial_output/app.env"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-admins
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    printf 'ServerOptions__Users__2__Password=%s\n' "$homelab_test_password" >>"$initial_output/app.env"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    write_http_auth_user homelab-test "$homelab_test_password" users-admins

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    printf 'FAVICON_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/favicons.env"
    ;;
speedtesttracker)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    app_key="$(load_secret ".$app_fullname.app.app_key" "dev=value=$(printf 'base64:' && openssl rand -base64 32)")"
    if [ "$mode" = 'dev' ]; then
        matej_email='matej@localhost'
    else
        matej_email='matej@matejhome.com'
    fi
    printf 'matej-email,%s\n' "$matej_email" >>"$initial_output/.secrets.csv"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'APP_KEY=%s\n' "$app_key" >>"$initial_output/app.env"
    printf 'ADMIN_NAME=Matej\n' >>"$initial_output/app.env"
    printf 'ADMIN_EMAIL=%s\n' "$matej_email" >>"$initial_output/app.env"
    printf 'ADMIN_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app.env"
    printf 'MAIL_PASSWORD=\n' >>"$initial_output/app.env"
    printf 'MAIL_USERNAME=\n' >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
tvheadend)
    # App
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-stream,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_stream_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
unbound)
    # Apache
    write_default_proxy_users "$app_fullname_key"

    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
unificontroller)
    # App
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-admin,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_admin_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)" >>"$initial_output/.secrets.csv"

    # MongoDB
    mongodb_password="$(load_secret ".$app_fullname_key.mongodb.user" dev=default)"
    printf 'mongodb,%s\n' "$mongodb_password" >>"$initial_output/.secrets.csv"
    printf '%s' "$mongodb_password" >>"$initial_output/mongodb-password.txt"
    printf 'MONGO_PASSWORD=%s\n' "$mongodb_password" >>"$initial_output/mongodb.env"
    printf 'MONGO_INITDB_ROOT_PASSWORD=%s\n' "$mongodb_password" >>"$initial_output/mongodb.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
uptimekuma)
    # App
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej" dev=default)" >>"$initial_output/.secrets.csv"

    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
vaultwarden)
    # App
    superadmin_password="$(load_secret ".$app_fullname_key.app.superadmin_user" dev=default)"
    superadmin_password_hashed="$(printf '%s' "$superadmin_password" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4 | sed 's~\$~$$~g')"
    printf 'ADMIN_TOKEN=%s\n' "$superadmin_password_hashed" >>"$initial_output/app.env"
    printf 'superadmin,%s\n' "$superadmin_password" >>"$initial_output/.secrets.csv"
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)" >>"$initial_output/.secrets.csv"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
vikunja)
    # App
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'MATEJ_PASSWORD=%s\n' "$matej_password" >>"$initial_output/app.env"

    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'HOMELAB_TEST_PASSWORD=%s\n' "$homelab_test_password" >>"$initial_output/app.env"

    jwt_secret="$(load_secret ".$app_fullname.app.jwt_secret" "dev=value=$(openssl rand -hex 32)")"
    printf 'jwt-secret,%s\n' "$jwt_secret" >>"$initial_output/.secrets.csv"
    printf 'VIKUNJA_SERVICE_JWTSECRET=%s\n' "$jwt_secret" >>"$initial_output/app.env"

    prometheus_password="$(load_secret ".$app_fullname_key.apache.prometheus_user" dev=default)"
    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"
    printf 'VIKUNJA_METRICS_PASSWORD=%s\n' "$prometheus_password" >>"$initial_output/app.env"

    # Apache
    write_default_proxy_users "$app_fullname_key"

    # Certificator
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons
    touch "$initial_output/favicons.env"
    ;;
*)
    printf 'Unknown app "%s" at "%s"\n' "$app_type" "$app_dir_path" >&2
    exit 1
    ;;
esac

# Lower permissions for all secret files
find "$initial_output" -type f -exec chmod 0400 {} \;

output='app-secrets'
if [ -e "$output" ]; then
    rm -rf "$output"
fi
cp -R "$initial_output" "$output"
# mkdir "$output"
# find "$initial_output" -mindepth 1 -maxdepth 1 -exec sh -c 'mv "$initial_output/$(basename "$1")" "$output/$(basename "$1")"' - \;

# Cleanup
rm -rf "$tmpdir"
