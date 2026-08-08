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

if [ "${GITHUB_ACTIONS:-}" = 'true' ] || [ "${CIRCLECI:-}" = 'true' ] || [ "${CI:-}" = '1' ] || [ "${CI:-}" = 'true' ]; then
    true # Check skipped on CI
elif [ ! -e "$SOPS_AGE_KEY_FILE" ]; then
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

    if [ "${GITHUB_ACTIONS:-}" = 'true' ] || [ "${CIRCLECI:-}" = 'true' ] || [ "${CI:-}" = '1' ] || [ "${CI:-}" = 'true' ]; then
        main_secret='N/A'
    else
        main_secret="$(sops --decrypt --config "$git_root_dir/secrets/.sops.yaml" "$git_root_dir/secrets/secrets.enc.yml" | yq -r "$1")"
        if [ "$main_secret" = '' ] || [ "$main_secret" = 'null' ] || [ "$main_secret" = 'undefined' ]; then
            printf 'Could not load secret "%s"\n' "$1" >&2
            exit 1
        fi
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

    printf 'HOMELAB_HEALTHCHECK_URL="%s"\n' "$healthcheck_url" >>"$initial_output/$2.env"
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
    printf 'PROXY_STATUS_PASSWORD="%s"\n' "$proxy_status_password" >>"$initial_output/apache-prometheus-exporter.env"
    printf 'proxy-status,%s\n' "$proxy_status_password" >>"$initial_output/.secrets.csv"

    proxy_prometheus_password="$(load_secret ".$1.apache.prometheus_user" dev=default)"
    write_http_auth_user proxy-prometheus "$proxy_prometheus_password" proxy-prometheus
    printf 'proxy-prometheus,%s\n' "$proxy_prometheus_password" >>"$initial_output/.secrets.csv"
}

write_certificator_users() {
    # No arguments
    certbot_certificator_password="$(load_secret '.certbot.app.certificator_user' dev=real)"
    printf 'CERTBOT_CERTIFICATOR_PASSWORD="%s"\n' "$certbot_certificator_password" >>"$initial_output/certificator.env"
}

case "$app_type" in
actualbudget)
    # Preload #
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"

    # App #
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

adventurelog)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    monika_password="$(load_secret ".$app_fullname_key.app.monika_user" dev=default)"
    django_password="$(load_secret ".$app_fullname_key.app.django_admin_user" dev=default)"
    secret_key="$(load_secret ".$app_fullname_key.app.secret_key" "dev=value=$(openssl rand -hex 32)")"
    postgis_password="$(load_secret ".$app_fullname_key.postgis.user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/.secrets.csv"

    printf 'DJANGO_ADMIN_PASSWORD="%s"\n' "$django_password" >>"$initial_output/app-backend.env"
    printf 'django-admin,%s\n' "$django_password" >>"$initial_output/.secrets.csv"

    printf 'SECRET_KEY="%s"\n' "$secret_key" >>"$initial_output/app-backend.env"
    printf 'secret-key,%s\n' "$secret_key" >>"$initial_output/.secrets.csv"

    # Postgis #
    printf 'PGPASSWORD="%s"\n' "$postgis_password" >>"$initial_output/app-backend.env"
    printf 'POSTGRES_PASSWORD="%s"\n' "$postgis_password" >>"$initial_output/postgis.env"
    printf 'postgis,%s\n' "$postgis_password" >>"$initial_output/.secrets.csv"

    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgis.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgis.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

changedetection)
    # Preload #
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"

    # App #
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

certbot)
    # Preload #
    certbot_matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    certbot_certificator_password="$(load_secret ".$app_fullname_key.app.certificator_user" dev=default)"
    certbot_homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    certbot_homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    certbot_public_email="$(load_secret ".$app_fullname_key.websupport.public_email" dev=empty)"
    websupport_api_key="$(load_secret ".$app_fullname_key.websupport.api_key" dev=empty)"
    websupport_api_secret="$(load_secret ".$app_fullname_key.websupport.api_secret" dev=empty)"
    websupport_service_id="$(load_secret ".$app_fullname_key.websupport.service_id" dev=empty)"

    # App #
    write_healthcheck_url "$app_fullname_key" app

    write_http_auth_user matej "$certbot_matej_password" proxy-prometheus
    write_http_auth_user matej "$certbot_matej_password" users-viewers
    write_http_auth_user matej "$certbot_matej_password" users-admins
    printf 'matej,%s\n' "$certbot_matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user certificator "$certbot_certificator_password" users-viewers
    printf 'certificator,%s\n' "$certbot_certificator_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$certbot_homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$certbot_homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$certbot_homelab_viewer_password" >>"$initial_output/all-credentials.csv"

    write_http_auth_user homelab-test "$certbot_homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$certbot_homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$certbot_homelab_test_password" >>"$initial_output/all-credentials.csv"

    printf 'CERTBOT_PUBLIC_EMAIL="%s"\n' "$certbot_public_email" >>"$initial_output/app.env"
    printf 'public-email,%s\n' "$certbot_public_email" >>"$initial_output/.secrets.csv"

    printf 'WEBSUPPORT_API_KEY="%s"\n' "$websupport_api_key" >>"$initial_output/app.env"
    printf 'websupport-api-key,%s\n' "$websupport_api_key" >>"$initial_output/.secrets.csv"

    printf 'WEBSUPPORT_API_SECRET="%s"\n' "$websupport_api_secret" >>"$initial_output/app.env"
    printf 'websupport-api-secret,%s\n' "$websupport_api_secret" >>"$initial_output/.secrets.csv"

    printf 'WEBSUPPORT_SERVICE_ID="%s"\n' "$websupport_service_id" >>"$initial_output/app.env"
    printf 'websupport-service-id,%s\n' "$websupport_service_id" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

dawarich)
    # Preload #
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    decryptor_key="$(load_secret ".$app_fullname_key.decryptor.secret_key" "dev=value=$(openssl rand -hex 16)")"
    postgis_password="$(load_secret ".$app_fullname_key.postgis.user" dev=default)"
    redis_password="$(load_secret ".$app_fullname_key.redis.user" dev=default)"
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    api_key="$(load_secret ".$app_fullname_key.app.api_key" dev=empty)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'api-key,%s\n' "$api_key" >>"$initial_output/.secrets.csv"

    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    # Decryptor #
    printf 'WEBUI_SECRET_KEY="%s"\n' "$decryptor_key" >>"$initial_output/app.env"
    printf 'SECRET_KEY="%s"\n' "$decryptor_key" >>"$initial_output/decryptor.env"
    printf 'secret-key,%s\n' "$decryptor_key" >>"$initial_output/.secrets.csv"

    # Postgis #
    printf 'DATABASE_PASSWORD="%s"\n' "$postgis_password" >>"$initial_output/app.env"
    printf 'POSTGRES_PASSWORD="%s"\n' "$postgis_password" >>"$initial_output/postgis.env"
    printf 'postgis,%s\n' "$postgis_password" >>"$initial_output/.secrets.csv"

    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgis.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgis.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # Redis #
    printf 'REDIS_PASSWORD="%s"\n' "$redis_password" >>"$initial_output/redis.env"
    printf 'REDIS_PASSWORD="%s"\n' "$redis_password" >>"$initial_output/app.env"
    printf 'redis,%s\n' "$redis_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

docker-cache)
    # Preload #
    http_secret="$(load_secret ".$app_fullname_key.app.http_secret" "dev=value=$(openssl rand -hex 16)")"
    redis_password="$(load_secret ".$app_fullname_key.redis.user" dev=default)"

    # App #
    printf 'REGISTRY_HTTP_SECRET="%s"\n' "$http_secret" >>"$initial_output/app.env"
    printf 'REGISTRY_PROXY_USERNAME=""\n' >>"$initial_output/app.env"
    printf 'REGISTRY_PROXY_PASSWORD=""\n' >>"$initial_output/app.env"

    # Redis #
    printf 'REDIS_PASSWORD="%s"\n' "$redis_password" >>"$initial_output/redis.env"
    printf 'REDIS_PASSWORD="%s"\n' "$redis_password" >>"$initial_output/app.env"
    printf 'redis,%s\n' "$redis_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

docker-stats)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # App #
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"

    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"

    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

donetick)
    # Preload #
    jwt_secret="$(load_secret ".$app_fullname_key.app.jwt_secret" "dev=value=$(openssl rand -base64 32 | base64)")"

    # App #
    printf 'DT_JWT_SECRET="%s"\n' "$jwt_secret" >>"$initial_output/app.env"
    printf 'jwt-secret,%s\n' "$jwt_secret" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

dozzle)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    hash_password_bcrypt "$matej_password" >"$tmpdir/matej-password-encrypted.txt"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    hash_password_bcrypt "$homelab_test_password" >"$tmpdir/homelab-test-password-encrypted.txt"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"

    printf 'users:\n' >>"$initial_output/dozzle-users.yml"
    printf '    matej:\n' >>"$initial_output/dozzle-users.yml"
    printf '        email: matej@%s\n' "$domain" >>"$initial_output/dozzle-users.yml"
    printf '        name: matej\n' >>"$initial_output/dozzle-users.yml"
    printf '        password: %s\n' "$(cat "$tmpdir/matej-password-encrypted.txt")" >>"$initial_output/dozzle-users.yml"
    printf '    homelab-test:\n' >>"$initial_output/dozzle-users.yml"
    printf '        email: homelab-test@homelab.%s\n' "$domain" >>"$initial_output/dozzle-users.yml"
    printf '        name: homelab-test\n' >>"$initial_output/dozzle-users.yml"
    printf '        password: %s\n' "$(cat "$tmpdir/homelab-test-password-encrypted.txt")" >>"$initial_output/dozzle-users.yml"

    # Dozzle-agent key
    openssl genpkey -algorithm RSA -out "$tmpdir/key.pem" -pkeyopt rsa_keygen_bits:2048
    openssl req -new -key "$tmpdir/key.pem" -out "$tmpdir/request.csr" -subj "/C=SK/ST=Slovakia/L=Bratislava/O=Homelab"
    openssl x509 -req -in "$tmpdir/request.csr" -signkey "$tmpdir/key.pem" -out "$tmpdir/cert.pem" -days 3650
    load_secret ".$app_fullname_key.app.agent_key" "dev=value=$(base64 <"$tmpdir/key.pem")" | base64 --decode >"$initial_output/dozzle-key.pem"
    load_secret ".$app_fullname_key.app.agent_cert" "dev=value=$(base64 <"$tmpdir/cert.pem")" | base64 --decode >"$initial_output/dozzle-cert.pem"
    rm -f "$tmpdir/key.pem" "$tmpdir/request.csr" "$tmpdir/cert.pem"

    # Apache #
    write_default_proxy_users dozzle

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

dozzle-agent)
    # App #
    openssl genpkey -algorithm RSA -out "$tmpdir/key.pem" -pkeyopt rsa_keygen_bits:2048
    openssl req -new -key "$tmpdir/key.pem" -out "$tmpdir/request.csr" -subj "/C=SK/ST=Slovakia/L=Bratislava/O=Homelab"
    openssl x509 -req -in "$tmpdir/request.csr" -signkey "$tmpdir/key.pem" -out "$tmpdir/cert.pem" -days 3650
    load_secret ".dozzle.app.agent_key" "dev=value=$(base64 <"$tmpdir/key.pem")" | base64 --decode >"$initial_output/dozzle-key.pem"
    load_secret ".dozzle.app.agent_cert" "dev=value=$(base64 <"$tmpdir/cert.pem")" | base64 --decode >"$initial_output/dozzle-cert.pem"
    rm -f "$tmpdir/key.pem" "$tmpdir/request.csr" "$tmpdir/cert.pem"
    ;;

gatus)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'PASSWORD_ENCRYPTED="%s"\n' "$(hash_password_bcrypt "$matej_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins

    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/all-credentials.csv"

    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/all-credentials.csv"

    # Main credentials
    printf 'CERTBOT__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.certbot.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h3.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h4_ultra.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_1__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.gatus_1.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_2__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.gatus_2.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'GOTIFY__TOKEN="%s"\n' "$(load_secret '.gotify.app.gatus_token' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.homepage.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'KIWIX_WIKIPEDIA__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.kiwix_wikipedia.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'KIWIX_WIKTIONARY__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.kiwix_wiktionary.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'LIBRETRANSLATE__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.libretranslate.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'MOTIONEYE_KITCHEN__STREAM_PASSWORD="%s"\n' "$(load_secret '.motioneye_kitchen.app.stream_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h3.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'NTFY__TOKEN="%s"\n' "$(load_secret '.ntfy.app.homelab_publisher_token' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.ollama.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.ollama_private.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.prometheus.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'RENOVATEBOT__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.renovatebot.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'SMTP4DEV__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.smtp4dev.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_1_blackhole.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_1_default.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_1_guests.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_1_internal.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_1_iot.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_1_matej.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_1_monika.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_2_blackhole.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_2_default.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_2_guests.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_2_internal.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_2_iot.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_2_matej.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__HOMELAB_VIEWER_PASSWORD="%s"\n' "$(load_secret '.unbound_2_monika.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__MATEJ_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_1.app.matej_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__MATEJ_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_2.app.matej_user' dev=real)" >>"$initial_output/app.env"

    # Other apps metrics credentials #
    printf 'DAWARICH__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.dawarich.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h3.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h4_ultra.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gatus_1.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gatus_2.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_PROJECT="%s"\n' "$(load_secret '.healthchecks.app.project_id' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_TOKEN="%s"\n' "$(load_secret '.healthchecks.app.api_key_readonly' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROMETHEUS_TOKEN="%s"\n' "$(load_secret '.homeassistant.app.homelab_viewer_api_key' dev=real)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.jellyfin.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'LIBRETRANSLATE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.libretranslate.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO__PROMETHEUS_TOKEN="%s"\n' "$(load_secret '.minio.app.prometheus_token' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h3.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_primary.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_secondary.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_blackhole.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_primary.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_secondary.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_blackhole.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.prometheus.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.samba_data.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_default.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_guests.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_iot.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_matej.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_monika.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_internal.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_blackhole.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_default.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_guests.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_iot.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_matej.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_monika.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_internal.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_blackhole.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__MATEJ_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_1.app.matej_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__MATEJ_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_2.app.matej_user' dev=real)" >>"$initial_output/app.env"

    # Other apps proxy metrics credentials #
    printf 'ACTUALBUDGET__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.actualbudget.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'ADVENTURELOG__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.adventurelog.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'CERTBOT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.certbot.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'CHANGEDETECTION__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.changedetection.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DAWARICH__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.dawarich.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_CACHE_DOCKERHUB__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_cache_dockerhub.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h3.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h4_ultra.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DONETICK__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.donetick.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOZZLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.dozzle.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gatus_1.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gatus_2.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GIT_CACHE_GITHUB__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.git_cache_github.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GOTIFY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gotify.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GRAFANA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.grafana.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GROCERIES__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.groceries.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.healthchecks.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.homeassistant.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.homepage.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.jellyfin.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'KIWIX_WIKIPEDIA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.kiwix_wikipedia.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'KIWIX_WIKTIONARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.kiwix_wiktionary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'KOFFAN__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.koffan.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'LIBRETRANSLATE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.libretranslate.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.minio.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO_CONSOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.minio.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MOTIONEYE_KITCHEN__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.motioneye_kitchen.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NETALERTX__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.netalertx.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h3.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NPM_CACHE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.npm_cache.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NTFY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.ntfy.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.ollama.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.ollama_private.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OMADACONTROLLER__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.omadacontroller.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OPENSPEEDTEST__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.openspeedtest.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OPENWEBUI__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.openwebui.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OPENWEBUI_PRIVATE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.openwebui_private.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_blackhole.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_primary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_secondary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_blackhole.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_primary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_secondary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PLANKA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.planka.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.prometheus.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'RENOVATEBOT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.renovatebot.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'REPORTPORTAL__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.reportportal.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.samba_data.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'SMTP4DEV__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.smtp4dev.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'SPEEDTESTTRACKER__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.speedtesttracker.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'TVHEADEND__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.tvheadend.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_blackhole.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_default.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_guests.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_internal.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_iot.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_matej.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_monika.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_blackhole.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_default.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_guests.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_internal.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_iot.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_matej.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_monika.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNIFICONTROLLER__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unificontroller.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_1.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_2.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'VAULTWARDEN__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.vaultwarden.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'VIKUNJA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.vikunja.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

git-cache)
    # Preload #
    postgres_password="$(load_secret ".$app_fullname_key.postgres.user" dev=default)"
    redis_password="$(load_secret ".$app_fullname_key.redis.user" dev=default)"

    # App #
    printf 'PGPASSWORD="%s"\n' "$postgres_password" >>"$initial_output/app.env"

    # Postgres #
    printf 'POSTGRES_PASSWORD="%s"\n' "$postgres_password" >>"$initial_output/postgres.env"
    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgres.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgres.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # Redis #
    printf 'REDIS_PASSWORD="%s"\n' "$redis_password" >>"$initial_output/redis.env"
    printf 'REDIS_PASSWORD="%s"\n' "$redis_password" >>"$initial_output/app.env"
    printf 'redis,%s\n' "$redis_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

gotify)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'GOTIFY_DEFAULTUSER_PASS="%s"\n' "$matej_password" >>"$initial_output/app.env"

    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

grafana)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'GF_SECURITY_ADMIN_PASSWORD="%s"\n' "$matej_password" >>"$initial_output/app.env"

    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

groceries)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    monika_password="$(load_secret ".$app_fullname_key.app.monika_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    couchdb_password="$(load_secret ".$app_fullname_key.couchdb.user" dev=default)"
    couchdb_hmac_key="$(load_secret ".$app_fullname_key.couchdb.hmac_key" dev=default)"
    couchdb_uuid="$(load_secret ".$app_fullname_key.couchdb.uuid" "dev=value=$(uuidgen)")"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    printf 'monika,%s\n' "$monika_password" >>"$initial_output/.secrets.csv"

    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'SMTP_PASSWORD="\n"' >>"$initial_output/app.env" # Placeholder

    # CouchDB #
    printf 'COUCHDB_ADMIN_PASSWORD="%s"\n' "$couchdb_password" >>"$initial_output/app.env"
    printf 'COUCHDB_PASSWORD="%s"\n' "$couchdb_password" >>"$initial_output/couchdb.env"
    printf 'couchdb-user,%s\n' "$couchdb_password" >>"$initial_output/.secrets.csv"

    printf 'COUCHDB_HMAC_KEY="%s"\n' "$couchdb_hmac_key" >>"$initial_output/app.env"
    printf 'HMAC_KEY="%s"\n' "$couchdb_hmac_key" >>"$initial_output/couchdb.env"
    printf 'couchdb-hmac,%s\n' "$couchdb_hmac_key" >>"$initial_output/.secrets.csv"

    printf 'UUID="%s"\n' "$couchdb_uuid" >>"$initial_output/couchdb.env"
    printf 'couchdb-uuid,%s\n' "$couchdb_uuid" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

healthchecks)
    # Preload #
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    secret_key="$(load_secret ".$app_fullname_key.app.secret_key" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'SECRET_KEY="%s"\n' "$secret_key" >>"$initial_output/app.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

homeassistant)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    monika_password="$(load_secret ".$app_fullname_key.app.monika_user" dev=default)"
    homelab_admin_password="$(load_secret ".$app_fullname_key.app.homelab_admin_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-admin,%s\n' "$homelab_admin_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

homepage)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Other services #
    printf 'HOMEPAGE_VAR__CHANGEDETECTION__APIKEY="%s"\n' "$(load_secret '.changedetection.app.api_key' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__GATUS_1__PASSWORD="%s"\n' "$(load_secret '.gatus-1.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__GATUS_2__PASSWORD="%s"\n' "$(load_secret '.gatus-2.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__GRAFANA__PASSWORD="%s"\n' "$(load_secret '.grafana.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__HEALTHCHECKS__APIKEY="%s"\n' "$(load_secret '.healthchecks.app.api_key_readonly' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__HOMEASSISTANT__APIKEY="%s"\n' "$(load_secret '.homeassistant.app.homelab_viewer_api_key' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__JELLYFIN__APIKEY="%s"\n' "$(load_secret '.jellyfin.app.homelab_api_key' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__MOTIONEYE_KITCHEN__HOMELAB_STREAM_PASSWORD="%s"\n' "$(load_secret '.motioneye_kitchen.app.homelab_stream_user' dev=real)" >>"$initial_output/app.env"
    # TODO: Enable NetAlertX integration
    # printf 'HOMEPAGE_VAR_NETALERTX_APIKEY="%s"\n' "$(load_secret '.netalertx.app.api_key' dev=real)" "$initial_output/app.env"
    printf 'HOMEPAGE_VAR__OMADACONTROLLER__PASSWORD="%s"\n' "$(load_secret 'omadacontroller.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_1_PRIMARY__PASSWORD="%s"\n' "$(load_secret 'pihole-1-primary.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_1_SECONDARY__PASSWORD="%s"\n' "$(load_secret 'pihole-1-secondary.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_1_BLACKHOLE__PASSWORD="%s"\n' "$(load_secret 'pihole-1-blackhole.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_2_PRIMARY__PASSWORD="%s"\n' "$(load_secret 'pihole-2-primary.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_2_SECONDARY__PASSWORD="%s"\n' "$(load_secret 'pihole-2-secondary.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PIHOLE_2_BLACKHOLE__PASSWORD="%s"\n' "$(load_secret 'pihole-2-blackhole.app.admin_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__PROMETHEUS__PASSWORD="%s"\n' "$(load_secret 'prometheus.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__SPEEDTESTTRACKER__APIKEY="%s"\n' "$(load_secret 'speedtesttracker.app.api_key_readonly' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__UNIFICONTROLLER__PASSWORD="%s"\n' "$(load_secret 'unificontroller.app.homelab_viewer_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE_VAR__VIKUNJA__APIKEY="%s"\n' "$(load_secret 'vikunja.app.api_key_readonly' dev=real)" >>"$initial_output/app.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    printf 'FAVICON_PASSWORD="%s"\n' "$homelab_viewer_password" >>"$initial_output/favicons.env"

    # Widgets
    printf 'PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.prometheus.app.homelab_viewer_user' dev=real)" >>"$initial_output/widgets.env"
    printf 'SMTP4DEV_PASSWORD="%s"\n' "$(load_secret '.smtp4dev.app.homelab_viewer_user' dev=real)" >>"$initial_output/widgets.env"
    ;;

jellyfin)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    monika_password="$(load_secret ".$app_fullname_key.app.monika_user" dev=default)"
    homelab_admin_password="$(load_secret ".$app_fullname_key.app.homelab_admin_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-admin,%s\n' "$homelab_admin_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"
    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

kiwix)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    monika_password="$(load_secret ".$app_fullname_key.app.monika_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user monika "$monika_password" users-viewers
    write_http_auth_user monika "$monika_password" users-admins
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

koffan)
    # Preload #
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"

    # App #
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"
    printf 'APP_PASSWORD="%s"\n' "$admin_password" >>"$initial_output/app.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

libretranslate)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    monika_password="$(load_secret ".$app_fullname_key.app.monika_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user monika "$monika_password" users-viewers
    write_http_auth_user monika "$monika_password" users-admins
    printf 'monika,%s\n' "$monika_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

minio)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_writer_password="$(load_secret ".$app_fullname_key.app.homelab_writer_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-writer,%s\n' "$homelab_writer_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'MINIO_ROOT_PASSWORD="%s"\n' "$matej_password" >>"$initial_output/app.env"

    # App setup #
    printf 'MINIO_MATEJ_PASSWORD="%s"\n' "$matej_password" >>"$initial_output/app-setup.env"
    printf 'MINIO_HOMELAB_WRITER_PASSWORD="%s"\n' "$homelab_writer_password" >>"$initial_output/app-setup.env"
    printf 'MINIO_HOMELAB_VIEWER_PASSWORD="%s"\n' "$homelab_viewer_password" >>"$initial_output/app-setup.env"
    printf 'MINIO_HOMELAB_TEST_PASSWORD="%s"\n' "$homelab_test_password" >>"$initial_output/app-setup.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

motioneye)
    # Preload #
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"
    stream_password="$(load_secret ".$app_fullname_key.app.stream_user" dev=default)"

    # App #
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"
    printf 'stream,%s\n' "$stream_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

nodeexporter)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

npm-cache)
    # Preload #
    redis_password="$(load_secret ".$app_fullname_key.redis.user" dev=default)"

    # Redis #
    printf 'REDIS_PASSWORD="%s"\n' "$redis_password" >>"$initial_output/redis.env"
    printf 'REDIS_PASSWORD="%s"\n' "$redis_password" >>"$initial_output/app.env"
    printf 'redis,%s\n' "$redis_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

ntfy)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_publisher_password="$(load_secret ".$app_fullname_key.app.homelab_publisher_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'NTFY_PASSWORD_MATEJ="%s"\n' "$matej_password" >>"$initial_output/app.env"

    printf 'homelab-publisher,%s\n' "$homelab_publisher_password" >>"$initial_output/.secrets.csv"
    printf 'NTFY_PASSWORD_HOMELAB_PUBLISHER="%s"\n' "$homelab_publisher_password" >>"$initial_output/app.env"

    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    printf 'NTFY_PASSWORD_HOMELAB_VIEWER="%s"\n' "$homelab_viewer_password" >>"$initial_output/app.env"

    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'NTFY_PASSWORD_HOMELAB_TEST="%s"\n' "$homelab_test_password" >>"$initial_output/app.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

ollama)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    openwebui_password="$(load_secret ".$app_fullname_key.app.openwebui_user" dev=default)"

    # App #
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user openwebui "$openwebui_password" users-viewers
    write_http_auth_user openwebui "$openwebui_password" users-admins
    printf 'openwebui,%s\n' "$openwebui_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

omadacontroller)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_admin_password="$(load_secret ".$app_fullname_key.app.homelab_admin_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-admin,%s\n' "$homelab_admin_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

openspeedtest)
    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

openwebui)
    # Preload #
    ollama_openwebui_password="$(load_secret '.ollama.app.openwebui_user' dev=real)"
    secret_key="$(load_secret ".$app_fullname_key.app.secret_key" "dev=value=$(openssl rand -hex 16)")"

    # App #
    printf 'OLLAMA_BASE_URL="%s"\n' "https://openwebui:$ollama_openwebui_password@$DOCKER_COMPOSE_OLLAMA_UPSTREAM_DOMAIN" >>"$initial_output/app.env"

    printf 'WEBUI_SECRET_KEY="%s"\n' "$secret_key" >>"$initial_output/app.env"
    printf 'secret-key,%s\n' "$secret_key" >>"$initial_output/.secrets.csv"
    printf 'matej,%s\n' "$(load_secret ".$app_fullname_key.app.matej_user" dev=default)" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

pihole)
    # Preload #
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # App #
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"
    printf 'FTLCONF_webserver_api_password="%s"\n' "$admin_password" >>"$initial_output/app.env"

    # App prometheus exporter #
    printf 'PIHOLE_PASSWORD="%s"\n' "$admin_password" >>"$initial_output/app-prometheus-exporter.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

planka)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    if [ "$mode" = 'dev' ]; then
        matej_email='matej@localhost'
    else
        matej_email='matej@matejhome.com'
    fi
    secret_key="$(load_secret ".$app_fullname.app.secret_key" "dev=value=$(openssl rand -hex 64)")"
    postgres_password="$(load_secret ".$app_fullname_key.postgres.user" dev=default)"

    # App #
    printf 'SECRET_KEY="%s"\n' "$secret_key" >>"$initial_output/app.env"
    printf 'secret-key,%s\n' "$secret_key" >>"$initial_output/.secrets.csv"

    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'DEFAULT_ADMIN_PASSWORD="%s"\n' "$matej_password" >>"$initial_output/app.env"
    printf 'DEFAULT_ADMIN_EMAIL="%s"\n' "$matej_email" >>"$initial_output/app.env"
    printf 'DEFAULT_ADMIN_USERNAME="%s"\n' "$(printf '%s' "$matej_email" | cut -d '@' -f 1)" >>"$initial_output/app.env"
    printf 'DEFAULT_ADMIN_NAME="%s"\n' "$(printf '%s' "$matej_email" | cut -d '@' -f 1 | awk '{print toupper(substr($0,0,1))substr($0,2)}')" >>"$initial_output/app.env"

    # Postgres #
    printf 'DATABASE_PASSWORD="%s"\n' "$postgres_password" >>"$initial_output/app.env"
    printf 'POSTGRES_PASSWORD="%s"\n' "$postgres_password" >>"$initial_output/postgres.env"
    printf 'postgres,%s\n' "$postgres_password" >>"$initial_output/.secrets.csv"

    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgres.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgres.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

prometheus)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'PROMETHEUS__MATEJ_PASSWORD_ENCRYPTED="%s"\n' "$(hash_password_bcrypt "$matej_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins

    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD_ENCRYPTED="%s"\n' "$(hash_password_bcrypt "$homelab_viewer_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD="%s"\n' "$homelab_viewer_password" >>"$initial_output/app.env"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers

    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'PROMETHEUS__HOMELAB_TEST_PASSWORD_ENCRYPTED="%s"\n' "$(hash_password_bcrypt "$homelab_test_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers

    printf 'app-prometheus,%s\n' "$prometheus_password" >>"$initial_output/.secrets.csv"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD_ENCRYPTED="%s"\n' "$(hash_password_bcrypt "$prometheus_password" | base64 | tr -d '\n')" >>"$initial_output/app.env"
    write_http_auth_user prometheus "$matej_password" prometheus

    # Other apps metrics credentials #
    printf 'DAWARICH__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.dawarich.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h3.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h4_ultra.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gatus_1.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gatus_2.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_PROJECT="%s"\n' "$(load_secret '.healthchecks.app.project_id' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROMETHEUS_TOKEN="%s"\n' "$(load_secret '.healthchecks.app.api_key_readonly' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROMETHEUS_TOKEN="%s"\n' "$(load_secret '.homeassistant.app.homelab_viewer_api_key' dev=real)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.jellyfin.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'LIBRETRANSLATE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.libretranslate.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO__PROMETHEUS_TOKEN="%s"\n' "$(load_secret '.minio.app.prometheus_token' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h3.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_primary.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_secondary.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_blackhole.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_primary.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_secondary.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_blackhole.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.prometheus.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.samba_data.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_default.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_guests.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_iot.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_matej.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_monika.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_internal.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_blackhole.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_default.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_guests.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_iot.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_matej.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_monika.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_internal.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_blackhole.app.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__MATEJ_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_1.app.matej_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__MATEJ_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_2.app.matej_user' dev=real)" >>"$initial_output/app.env"

    # Other apps proxy metrics credentials #
    printf 'ACTUALBUDGET__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.actualbudget.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'ADVENTURELOG__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.adventurelog.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'CERTBOT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.certbot.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'CHANGEDETECTION__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.changedetection.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DAWARICH__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.dawarich.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_CACHE_DOCKERHUB__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_cache_dockerhub.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H3__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h3.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_odroid_h4_ultra.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DONETICK__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.donetick.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'DOZZLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.dozzle.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_1__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gatus_1.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GATUS_2__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gatus_2.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GIT_CACHE_GITHUB__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.git_cache_github.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GOTIFY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.gotify.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GRAFANA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.grafana.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'GROCERIES__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.groceries.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HEALTHCHECKS__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.healthchecks.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEASSISTANT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.homeassistant.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'HOMEPAGE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.homepage.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'JELLYFIN__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.jellyfin.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'KIWIX_WIKIPEDIA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.kiwix_wikipedia.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'KIWIX_WIKTIONARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.kiwix_wiktionary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'KOFFAN__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.koffan.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'LIBRETRANSLATE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.libretranslate.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.minio.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MINIO_CONSOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.minio.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'MOTIONEYE_KITCHEN__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.motioneye_kitchen.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NETALERTX__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.netalertx.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H3__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h3.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NPM_CACHE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.npm_cache.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'NTFY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.ntfy.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.ollama.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OLLAMA_PRIVATE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.ollama_private.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OMADACONTROLLER__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.omadacontroller.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OPENSPEEDTEST__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.openspeedtest.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OPENWEBUI__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.openwebui.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'OPENWEBUI_PRIVATE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.openwebui_private.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_blackhole.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_PRIMARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_primary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_1_SECONDARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_1_secondary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_blackhole.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_PRIMARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_primary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PIHOLE_2_SECONDARY__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.pihole_2_secondary.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PLANKA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.planka.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'PROMETHEUS__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.prometheus.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'RENOVATEBOT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.renovatebot.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'REPORTPORTAL__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.reportportal.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'SAMBA_DATA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.samba_data.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'SMTP4DEV__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.smtp4dev.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'SPEEDTESTTRACKER__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.speedtesttracker.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'TVHEADEND__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.tvheadend.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_blackhole.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_DEFAULT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_default.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_GUESTS__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_guests.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_INTERNAL__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_internal.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_IOT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_iot.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MATEJ__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_matej.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_1_MONIKA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_1_monika.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_blackhole.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_DEFAULT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_default.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_GUESTS__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_guests.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_INTERNAL__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_internal.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_IOT__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_iot.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MATEJ__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_matej.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNBOUND_2_MONIKA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unbound_2_monika.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UNIFICONTROLLER__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.unificontroller.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_1__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_1.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'UPTIMEKUMA_2__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.uptimekuma_2.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'VAULTWARDEN__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.vaultwarden.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"
    printf 'VIKUNJA__PROXY_PROMETHEUS_PASSWORD="%s"\n' "$(load_secret '.vikunja.apache.prometheus_user' dev=real)" >>"$initial_output/app.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    printf 'FAVICON_PASSWORD=%s\n' "$homelab_viewer_password" >>"$initial_output/favicons.env"
    ;;

renovatebot)
    # Preload #
    renovate_token="$(load_secret ".$app_fullname.app.renovate_token" dev=real)" # PAT specific for each git host
    github_token="$(load_secret ".$app_fullname.app.github_token" dev=real)"     # GitHub PAT (even if using other git hosts)
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    write_healthcheck_url "$app_fullname_key" app
    printf 'RENOVATE_TOKEN="%s"\n' "$renovate_token" >>"$initial_output/app.env"
    printf 'GITHUB_COM_TOKEN="%s"\n' "$github_token" >>"$initial_output/app.env"
    printf 'renovate-token,%s\n' "$renovate_token" >>"$initial_output/.secrets.csv"
    printf 'github-token,%s\n' "$github_token" >>"$initial_output/.secrets.csv"

    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

reportportal)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    admin_password="$(load_secret ".$app_fullname_key.app.admin_user" dev=default)"
    postgres_password="$(load_secret ".$app_fullname_key.postgres.user" dev=default)"
    rabbitmq_password="$(load_secret ".$app_fullname_key.rabbitmq.user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'admin,%s\n' "$admin_password" >>"$initial_output/.secrets.csv"
    printf 'RP_INITIAL_ADMIN_PASSWORD="%s"\n' "$admin_password" >>"$initial_output/app-uat.env"
    printf 'RP_DB_PASS="%s"\n' "$postgres_password" >>"$initial_output/app-api.env"
    printf 'RP_AMQP_PASS="%s"\n' "$rabbitmq_password" >>"$initial_output/app-api.env"
    printf 'RP_AMQP_APIPASS="%s"\n' "$rabbitmq_password" >>"$initial_output/app-api.env"
    printf 'RP_DB_PASS="%s"\n' "$postgres_password" >>"$initial_output/app-uat.env"
    printf 'RP_AMQP_PASS="%s"\n' "$rabbitmq_password" >>"$initial_output/app-uat.env"
    printf 'RP_AMQP_APIPASS="%s"\n' "$rabbitmq_password" >>"$initial_output/app-uat.env"
    printf 'RP_DB_PASS="%s"\n' "$postgres_password" >>"$initial_output/app-jobs.env"
    printf 'RP_AMQP_PASS="%s"\n' "$rabbitmq_password" >>"$initial_output/app-jobs.env"
    printf 'RP_AMQP_APIPASS="%s"\n' "$rabbitmq_password" >>"$initial_output/app-jobs.env"
    printf 'POSTGRES_PASSWORD="%s"\n' "$postgres_password" >>"$initial_output/app-migrations.env"
    printf 'AMQP_URL="%s%s%s%s"\n' 'amqp://' 'rabbitmq:' "$rabbitmq_password" '@rabbitmq:5672' >>"$initial_output/app-analyzer.env"

    # Postgres #
    printf 'postgres,%s\n' "$postgres_password" >>"$initial_output/.secrets.csv"
    printf 'POSTGRES_PASSWORD="%s"\n' "$postgres_password" >>"$initial_output/postgres.env"
    openssl req -new -x509 -days 3650 -nodes -text -out "$tmpdir/postgres-dev.crt" -keyout "$tmpdir/postgres-dev.key" -subj '/CN=postgres'
    load_secret ".$app_fullname_key.postgres.ca_certificate" "dev=value=$(cat "$tmpdir/postgres-dev.crt")" >"$initial_output/postgres.crt"
    load_secret ".$app_fullname_key.postgres.ca_private_key" "dev=value=$(cat "$tmpdir/postgres-dev.key")" >"$initial_output/postgres.key"
    rm -f "$tmpdir/postgres-dev.crt" "$tmpdir/postgres-dev.key"

    # RabbitMQ
    printf 'rabbitmq,%s\n' "$rabbitmq_password" >>"$initial_output/.secrets.csv"
    printf 'RABBITMQ_DEFAULT_PASS="%s"\n' "$rabbitmq_password" >>"$initial_output/rabbitmq.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

samba)
    # Preload #
    smb_password="$(load_secret ".$app_fullname_key.app.user" dev=default)"
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # App #
    printf 'admin,%s\n' "$smb_password" >>"$initial_output/.secrets.csv"
    printf 'SAMBA_PASSWORD="%s"\n' "$smb_password" >>"$initial_output/app.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

smtp4dev)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    printf 'ServerOptions__Users__0__Password="%s"\n' "$matej_password" >>"$initial_output/app.env"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins

    printf 'ServerOptions__Users__1__Password="%s"\n' "$homelab_viewer_password" >>"$initial_output/app.env"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-admins

    printf 'ServerOptions__Users__2__Password="%s"\n' "$homelab_test_password" >>"$initial_output/app.env"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    write_http_auth_user homelab-test "$homelab_test_password" users-admins

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    printf 'FAVICON_PASSWORD="%s"\n' "$homelab_viewer_password" >>"$initial_output/favicons.env"
    ;;

speedtesttracker)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    if [ "$mode" = 'dev' ]; then
        matej_email='matej@localhost'
    else
        matej_email='matej@matejhome.com'
    fi
    app_key="$(load_secret ".$app_fullname.app.app_key" "dev=value=$(printf 'base64:' && openssl rand -base64 32)")"

    # App #
    printf 'matej-email,%s\n' "$matej_email" >>"$initial_output/.secrets.csv"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'APP_KEY="%s"\n' "$app_key" >>"$initial_output/app.env"
    printf 'ADMIN_NAME="Matej"\n' >>"$initial_output/app.env"
    printf 'ADMIN_EMAIL="%s"\n' "$matej_email" >>"$initial_output/app.env"
    printf 'ADMIN_PASSWORD="%s"\n' "$matej_password" >>"$initial_output/app.env"
    printf 'MAIL_PASSWORD=""\n' >>"$initial_output/app.env"
    printf 'MAIL_USERNAME=""\n' >>"$initial_output/app.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

tvheadend)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_stream_password="$(load_secret ".$app_fullname_key.app.homelab_stream_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-stream,%s\n' "$homelab_stream_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

unbound)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    write_http_auth_user matej "$matej_password" prometheus
    write_http_auth_user matej "$matej_password" proxy-prometheus
    write_http_auth_user matej "$matej_password" users-viewers
    write_http_auth_user matej "$matej_password" users-admins
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-viewer "$homelab_viewer_password" prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" proxy-prometheus
    write_http_auth_user homelab-viewer "$homelab_viewer_password" users-viewers
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user homelab-test "$homelab_test_password" prometheus
    write_http_auth_user homelab-test "$homelab_test_password" proxy-prometheus
    write_http_auth_user homelab-test "$homelab_test_password" users-viewers
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

unificontroller)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_admin_password="$(load_secret ".$app_fullname_key.app.homelab_admin_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    mongodb_password="$(load_secret ".$app_fullname_key.mongodb.user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-admin,%s\n' "$homelab_admin_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"

    # MongoDB
    printf 'mongodb,%s\n' "$mongodb_password" >>"$initial_output/.secrets.csv"
    printf '%s' "$mongodb_password" >>"$initial_output/mongodb-password.txt"
    printf 'MONGO_PASSWORD="%s"\n' "$mongodb_password" >>"$initial_output/mongodb.env"
    printf 'MONGO_INITDB_ROOT_PASSWORD="%s"\n' "$mongodb_password" >>"$initial_output/mongodb.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

uptimekuma)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"

    write_http_auth_user prometheus "$app_prometheus_password" prometheus
    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

vaultwarden)
    # Preload #
    superadmin_password="$(load_secret ".$app_fullname_key.app.superadmin_user" dev=default)"
    superadmin_password_hashed="$(printf '%s' "$superadmin_password" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4 | sed 's~\$~$$~g')"
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_viewer_password="$(load_secret ".$app_fullname_key.app.homelab_viewer_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"

    # App #
    printf 'ADMIN_TOKEN="%s"\n' "$superadmin_password_hashed" >>"$initial_output/app.env"
    printf 'superadmin,%s\n' "$superadmin_password" >>"$initial_output/.secrets.csv"
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-viewer,%s\n' "$homelab_viewer_password" >>"$initial_output/.secrets.csv"
    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

vikunja)
    # Preload #
    matej_password="$(load_secret ".$app_fullname_key.app.matej_user" dev=default)"
    homelab_test_password="$(load_secret ".$app_fullname_key.app.homelab_test_user" dev=default)"
    jwt_secret="$(load_secret ".$app_fullname.app.jwt_secret" "dev=value=$(openssl rand -hex 32)")"
    app_prometheus_password="$(load_secret ".$app_fullname_key.app.prometheus_user" dev=default)"

    # App #
    printf 'matej,%s\n' "$matej_password" >>"$initial_output/.secrets.csv"
    printf 'MATEJ_PASSWORD="%s"\n' "$matej_password" >>"$initial_output/app.env"

    printf 'homelab-test,%s\n' "$homelab_test_password" >>"$initial_output/.secrets.csv"
    printf 'HOMELAB_TEST_PASSWORD="%s"\n' "$homelab_test_password" >>"$initial_output/app.env"

    printf 'jwt-secret,%s\n' "$jwt_secret" >>"$initial_output/.secrets.csv"
    printf 'VIKUNJA_SERVICE_JWTSECRET="%s"\n' "$jwt_secret" >>"$initial_output/app.env"

    printf 'app-prometheus,%s\n' "$app_prometheus_password" >>"$initial_output/.secrets.csv"
    printf 'VIKUNJA_METRICS_PASSWORD="%s"\n' "$app_prometheus_password" >>"$initial_output/app.env"

    # Apache #
    write_default_proxy_users "$app_fullname_key"

    # Certificator #
    write_certificator_users
    write_healthcheck_url "$app_fullname_key" certificator

    # Favicons #
    touch "$initial_output/favicons.env"
    ;;

*)
    printf 'Unknown app "%s" at "%s"\n' "$app_type" "$app_dir_path" >&2
    exit 1
    ;;
esac

# Lower permissions for all secret files
find "$initial_output" -type f -exec chmod 0400 {} \;

final_output='app-secrets'
if [ -e "$final_output" ]; then
    rm -rf "$final_output"
fi
cp -R "$initial_output" "$final_output"
# mkdir "$output"
# find "$initial_output" -mindepth 1 -maxdepth 1 -exec sh -c 'mv "$initial_output/$(basename "$1")" "$output/$(basename "$1")"' - \;

# Cleanup
rm -rf "$tmpdir"
