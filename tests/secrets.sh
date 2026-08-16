#!/bin/sh
set -euf

cd "$(dirname "$0")"
git_root_dir="$(git rev-parse --show-toplevel)"

if [ "${BW_SESSION-}" = '' ]; then
    echo 'You must set BW_SESSION env variable before calling this script.' >&2
    exit 1
fi

# Set SOPS decryption key file
SOPS_AGE_KEY_FILE="$git_root_dir/secrets/key.txt"
export SOPS_AGE_KEY_FILE

load_secret() {
    # $1 - yq query

    if [ "$#" -lt 1 ]; then
        printf 'Missing arguments for load_secret() function, got: %s\n' "$#" >&2
        exit 1
    fi

    secret="$(sops --decrypt --config "$git_root_dir/secrets/.sops.yml" "$git_root_dir/secrets/secrets.enc.yml" | yq -r "$1")"
    if [ "$secret" = '' ] || [ "$secret" = 'null' ] || [ "$secret" = 'undefined' ]; then
        printf 'Could not load secret "%s"\n' "$1" >&2
        exit 1
    fi

    printf '%s\n' "$secret"
}

rm -f .secrets.env

{
    set -euf

    printf 'ACTUALBUDGET__ADMIN_PASSWORD=%s\n' "$(load_secret '.actualbudget.app.admin_user')"
    printf 'ACTUALBUDGET__ENCRYPTION_PASSWORD=%s\n' "$(load_secret '.actualbudget.app.encryption_key')"
    printf 'ACTUALBUDGET__SYNC_ID=%s\n' "$(load_secret '.actualbudget.app.sync_id')"
    printf 'ACTUALBUDGET__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.actualbudget.apache.status_user')"
    printf 'ACTUALBUDGET__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.actualbudget.apache.prometheus_user')"

    printf 'ADVENTURELOG__MATEJ_PASSWORD=%s\n' "$(load_secret '.adventurelog.app.matej_user')"
    printf 'ADVENTURELOG__MONIKA_PASSWORD=%s\n' "$(load_secret '.adventurelog.app.monika_user')"
    printf 'ADVENTURELOG__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.adventurelog.app.homelab_test_user')"
    printf 'ADVENTURELOG__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.adventurelog.apache.status_user')"
    printf 'ADVENTURELOG__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.adventurelog.apache.prometheus_user')"
    printf 'ADVENTURELOG_BACKEND__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.adventurelog.apache.status_user')"
    printf 'ADVENTURELOG_BACKEND__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.adventurelog.apache.prometheus_user')"

    printf 'CERTBOT__MATEJ_PASSWORD=%s\n' "$(load_secret '.certbot.app.matej_user')"
    printf 'CERTBOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.certbot.app.homelab_viewer_user')"
    printf 'CERTBOT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.certbot.app.homelab_test_user')"
    printf 'CERTBOT__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.certbot.apache.status_user')"
    printf 'CERTBOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.certbot.apache.prometheus_user')"

    printf 'CHANGEDETECTION__ADMIN_PASSWORD=%s\n' "$(load_secret '.changedetection.app.admin_user')"
    printf 'CHANGEDETECTION__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.changedetection.apache.status_user')"
    printf 'CHANGEDETECTION__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.changedetection.apache.prometheus_user')"

    printf 'DAWARICH__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.dawarich.app.homelab_test_user')"
    printf 'DAWARICH__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.dawarich.apache.status_user')"
    printf 'DAWARICH__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.dawarich.apache.prometheus_user')"
    printf 'DAWARICH__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.dawarich.app.prometheus_user')"

    printf 'DOCKER_CACHE_DOCKERHUB__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.docker_cache_dockerhub.apache.status_user')"
    printf 'DOCKER_CACHE_DOCKERHUB__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_cache_dockerhub.apache.prometheus_user')"

    printf 'DOCKER_STATS_ODROID_H3__MATEJ_PASSWORD=%s\n' "$(load_secret .'docker_stats_odroid_h3.app.matej_user')"
    printf 'DOCKER_STATS_ODROID_H3__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret .'docker_stats_odroid_h3.app.homelab_viewer_user')"
    printf 'DOCKER_STATS_ODROID_H3__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret .'docker_stats_odroid_h3.app.homelab_test_user')"
    printf 'DOCKER_STATS_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_secret .'docker_stats_odroid_h3.app.prometheus_user')"
    printf 'DOCKER_STATS_ODROID_H3__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret .'docker_stats_odroid_h3.apache.status_user')"
    printf 'DOCKER_STATS_ODROID_H3__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret .'docker_stats_odroid_h3.apache.prometheus_user')"

    printf 'DOCKER_STATS_ODROID_H4_ULTRA__MATEJ_PASSWORD=%s\n' "$(load_secret '.docker_stats_odroid_h4_ultra.app.matej_user')"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.docker_stats_odroid_h4_ultra.app.homelab_viewer_user')"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.docker_stats_odroid_h4_ultra.app.homelab_test_user')"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_odroid_h4_ultra.app.prometheus_user')"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_odroid_h4_ultra.apache.status_user')"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_odroid_h4_ultra.apache.prometheus_user')"

    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__MATEJ_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.app.matej_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.app.homelab_viewer_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.app.homelab_test_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.app.prometheus_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.apache.status_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_2g.apache.prometheus_user')"

    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__MATEJ_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.app.matej_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.app.homelab_viewer_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.app.homelab_test_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.app.prometheus_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.apache.status_user')"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.docker_stats_raspberry_pi_4b_4g.apache.prometheus_user')"

    printf 'DOZZLE__MATEJ_PASSWORD=%s\n' "$(load_secret '.dozzle.app.matej_user')"
    printf 'DOZZLE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.dozzle.app.homelab_test_user')"
    printf 'DOZZLE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.dozzle.apache.status_user')"
    printf 'DOZZLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.dozzle.apache.prometheus_user')"

    printf 'GATUS_1__MATEJ_PASSWORD=%s\n' "$(load_secret '.gatus_1.app.matej_user')"
    printf 'GATUS_1__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.gatus_1.app.homelab_viewer_user')"
    printf 'GATUS_1__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.gatus_1.app.homelab_test_user')"
    printf 'GATUS_1__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gatus_1.app.prometheus_user')"
    printf 'GATUS_1__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.gatus_1.apache.status_user')"
    printf 'GATUS_1__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gatus_1.apache.prometheus_user')"

    printf 'GATUS_2__MATEJ_PASSWORD=%s\n' "$(load_secret '.gatus_2.app.matej_user')"
    printf 'GATUS_2__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.gatus_2.app.homelab_viewer_user')"
    printf 'GATUS_2__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.gatus_2.app.homelab_test_user')"
    printf 'GATUS_2__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gatus_2.app.prometheus_user')"
    printf 'GATUS_2__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.gatus_2.apache.status_user')"
    printf 'GATUS_2__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gatus_2.apache.prometheus_user')"

    printf 'GIT_CACHE_GITHUB__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.git_cache_github.apache.status_user')"
    printf 'GIT_CACHE_GITHUB__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.git_cache_github.apache.prometheus_user')"

    printf 'GOTIFY__MATEJ_PASSWORD=%s\n' "$(load_secret '.gotify.app.matej_user')"
    printf 'GOTIFY__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.gotify.app.homelab_test_user')"
    printf 'GOTIFY__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.gotify.apache.status_user')"
    printf 'GOTIFY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.gotify.apache.prometheus_user')"

    printf 'GRAFANA__MATEJ_PASSWORD=%s\n' "$(load_secret '.grafana.app.matej_user')"
    printf 'GRAFANA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.grafana.app.homelab_viewer_user')"
    printf 'GRAFANA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.grafana.app.homelab_test_user')"
    printf 'GRAFANA__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.grafana.apache.status_user')"
    printf 'GRAFANA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.grafana.apache.prometheus_user')"

    printf 'GROCERIES__HOMELABTEST_PASSWORD=%s\n' "$(load_secret '.groceries.app.homelab_test_user')"
    printf 'GROCERIES__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.groceries.apache.status_user')"
    printf 'GROCERIES__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.groceries.apache.prometheus_user')"

    printf 'HEALTHCHECKS__MATEJ_PASSWORD=%s\n' "$(load_secret '.healthchecks.app.matej_user')"
    printf 'HEALTHCHECKS__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.healthchecks.app.homelab_test_user')"
    printf 'HEALTHCHECKS__API_KEY_READONLY=%s\n' "$(load_secret '.healthchecks.app.api_key_readonly')"
    printf 'HEALTHCHECKS__API_KEY_READWRITE=%s\n' "$(load_secret '.healthchecks.app.api_key_readwrite')"
    printf 'HEALTHCHECKS__PING_KEY=%s\n' "$(load_secret '.healthchecks.app.ping_key')"
    printf 'HEALTHCHECKS__PROMETHEUS_PROJECT=%s\n' "$(load_secret '.healthchecks.app.project_id')"
    printf 'HEALTHCHECKS__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.healthchecks.apache.status_user')"
    printf 'HEALTHCHECKS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.healthchecks.apache.prometheus_user')"

    printf 'HOMEASSISTANT__MATEJ_PASSWORD=%s\n' "$(load_secret '.homeassistant.app.matej_user')"
    printf 'HOMEASSISTANT__HOMELAB_ADMIN_PASSWORD=%s\n' "$(load_secret '.homeassistant.app.homelab_admin_user')"
    printf 'HOMEASSISTANT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.homeassistant.app.homelab_viewer_user')"
    printf 'HOMEASSISTANT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.homeassistant.app.homelab_test_user')"
    printf 'HOMEASSISTANT__PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_secret '.homeassistant.app.homelab_viewer_api_key')"
    printf 'HOMEASSISTANT__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.homeassistant.apache.status_user')"
    printf 'HOMEASSISTANT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.homeassistant.apache.prometheus_user')"

    printf 'HOMEPAGE__MATEJ_PASSWORD=%s\n' "$(load_secret '.homepage.app.matej_user')"
    printf 'HOMEPAGE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.homepage.app.homelab_viewer_user')"
    printf 'HOMEPAGE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.homepage.app.homelab_test_user')"
    printf 'HOMEPAGE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.homepage.apache.status_user')"
    printf 'HOMEPAGE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.homepage.apache.prometheus_user')"

    printf 'JELLYFIN__MATEJ_PASSWORD=%s\n' "$(load_secret '.jellyfin.app.matej_user')"
    printf 'JELLYFIN__MONIKA_PASSWORD=%s\n' "$(load_secret '.jellyfin.app.monika_user')"
    printf 'JELLYFIN__HOMELAB_ADMIN_PASSWORD=%s\n' "$(load_secret '.jellyfin.app.homelab_admin_user')"
    printf 'JELLYFIN__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.jellyfin.app.homelab_test_user')"
    printf 'JELLYFIN__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.jellyfin.app.prometheus_user')"
    printf 'JELLYFIN__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.jellyfin.apache.status_user')"
    printf 'JELLYFIN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.jellyfin.apache.prometheus_user')"

    printf 'KOFFAN__APP_PASSWORD=%s\n' "$(load_secret '.koffan.app.admin_user')"
    printf 'KOFFAN__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.koffan.apache.status_user')"
    printf 'KOFFAN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.koffan.apache.prometheus_user')"

    printf 'LIBRETRANSLATE__MATEJ_PASSWORD=%s\n' "$(load_secret '.libretranslate.app.matej_user')"
    printf 'LIBRETRANSLATE__MONIKA_PASSWORD=%s\n' "$(load_secret '.libretranslate.app.monika_user')"
    printf 'LIBRETRANSLATE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.libretranslate.app.homelab_viewer_user')"
    printf 'LIBRETRANSLATE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.libretranslate.app.homelab_test_user')"
    printf 'LIBRETRANSLATE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.libretranslate.app.prometheus_user')"
    printf 'LIBRETRANSLATE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.libretranslate.apache.status_user')"
    printf 'LIBRETRANSLATE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.libretranslate.apache.prometheus_user')"

    printf 'MINIO__MATEJ_PASSWORD=%s\n' "$(load_secret '.minio.app.matej_user')"
    printf 'MINIO__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.minio.app.homelab_viewer_user')"
    printf 'MINIO__HOMELAB_WRITER_PASSWORD=%s\n' "$(load_secret '.minio.app.homelab_writer_user')"
    printf 'MINIO__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.minio.app.homelab_test_user')"
    printf 'MINIO__PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_secret '.minio.app.prometheus_token')"
    printf 'MINIO__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.minio.apache.status_user')"
    printf 'MINIO__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.minio.apache.prometheus_user')"
    printf 'MINIO_CONSOLE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.minio.apache.status_user')"
    printf 'MINIO_CONSOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.minio.apache.prometheus_user')"

    printf 'MOTIONEYE_KITCHEN__ADMIN_PASSWORD=%s\n' "$(load_secret '.motioneye_kitchen.app.admin_user')"
    printf 'MOTIONEYE_KITCHEN__STREAM_PASSWORD=%s\n' "$(load_secret '.motioneye_kitchen.app.stream_user')"
    printf 'MOTIONEYE_KITCHEN__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.motioneye_kitchen.apache.status_user')"
    printf 'MOTIONEYE_KITCHEN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.motioneye_kitchen.apache.prometheus_user')"

    printf 'NODEEXPORTER_ODROID_H3__MATEJ_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h3.app.matej_user')"
    printf 'NODEEXPORTER_ODROID_H3__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h3.app.homelab_viewer_user')"
    printf 'NODEEXPORTER_ODROID_H3__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h3.app.homelab_test_user')"
    printf 'NODEEXPORTER_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h3.app.prometheus_user')"
    printf 'NODEEXPORTER_ODROID_H3__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h3.apache.status_user')"
    printf 'NODEEXPORTER_ODROID_H3__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h3.apache.prometheus_user')"

    printf 'NODEEXPORTER_ODROID_H4_ULTRA__MATEJ_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.app.matej_user')"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.app.homelab_viewer_user')"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.app.homelab_test_user')"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.app.prometheus_user')"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.apache.status_user')"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_odroid_h4_ultra.apache.prometheus_user')"

    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__MATEJ_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.app.matej_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.app.homelab_viewer_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.app.homelab_test_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.app.prometheus_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.apache.status_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_2g.apache.prometheus_user')"

    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__MATEJ_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.app.matej_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.app.homelab_viewer_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.app.homelab_test_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.app.prometheus_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.apache.status_user')"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.nodeexporter_raspberry_pi_4b_4g.apache.prometheus_user')"

    printf 'NPM_CACHE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.npm_cache.apache.status_user')"
    printf 'NPM_CACHE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.npm_cache.apache.prometheus_user')"

    printf 'NTFY__MATEJ_PASSWORD=%s\n' "$(load_secret '.ntfy.app.matej_user')"
    printf 'NTFY__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.ntfy.app.homelab_test_user')"
    printf 'NTFY__HOMELAB_PUBLISHER_PASSWORD=%s\n' "$(load_secret '.ntfy.app.homelab_publisher_user')"
    printf 'NTFY__HOMELAB_PUBLISHER_TOKEN=%s\n' "$(load_secret '.ntfy.app.homelab_publisher_token')"
    printf 'NTFY__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.ntfy.apache.status_user')"
    printf 'NTFY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ntfy.apache.prometheus_user')"

    # TODO: Enable NetAlertX
    # printf 'NETALERTX__ADMIN_PASSWORD=%s\n' "$(load_secret '.netalertx.app.admin_user')"
    # printf 'NETALERTX__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.netalertx.app.prometheus_user')"
    # printf 'NETALERTX__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.ntfy.apache.status_user')"
    # printf 'NETALERTX__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ntfy.apache.prometheus_user')"

    printf 'OLLAMA__MATEJ_PASSWORD=%s\n' "$(load_secret '.ollama.app.matej_user')"
    printf 'OLLAMA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.ollama.app.homelab_viewer_user')"
    printf 'OLLAMA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.ollama.app.homelab_test_user')"
    printf 'OLLAMA__OPENWEBUI_PASSWORD=%s\n' "$(load_secret '.ollama.app.openwebui_user')"
    printf 'OLLAMA__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.ollama.apache.status_user')"
    printf 'OLLAMA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ollama.apache.prometheus_user')"

    printf 'OLLAMA_PRIVATE__MATEJ_PASSWORD=%s\n' "$(load_secret '.ollama_private.app.matej_user')"
    printf 'OLLAMA_PRIVATE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.ollama_private.app.homelab_viewer_user')"
    printf 'OLLAMA_PRIVATE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.ollama_private.app.homelab_test_user')"
    printf 'OLLAMA_PRIVATE__OPENWEBUI_PASSWORD=%s\n' "$(load_secret '.ollama_private.app.openwebui_user')"
    printf 'OLLAMA_PRIVATE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.ollama_private.apache.status_user')"
    printf 'OLLAMA_PRIVATE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.ollama_private.apache.prometheus_user')"

    printf 'OMADACONTROLLER__HOMELAB_ADMIN_PASSWORD=%s\n' "$(load_secret '.omadacontroller.app.homelab_admin_user')"
    printf 'OMADACONTROLLER__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.omadacontroller.app.homelab_test_user')"
    printf 'OMADACONTROLLER__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.omadacontroller.app.homelab_viewer_user')"
    printf 'OMADACONTROLLER__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.omadacontroller.apache.status_user')"
    printf 'OMADACONTROLLER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.omadacontroller.apache.prometheus_user')"

    printf 'OPENWEBUI__MATEJ_PASSWORD=%s\n' "$(load_secret '.openwebui.app.matej_user')"
    printf 'OPENWEBUI__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.openwebui.app.homelab_test_user')"
    printf 'OPENWEBUI__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.openwebui.apache.status_user')"
    printf 'OPENWEBUI__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.openwebui.apache.prometheus_user')"

    printf 'OPENWEBUI_PRIVATE__MATEJ_PASSWORD=%s\n' "$(load_secret '.openwebui_private.app.matej_user')"
    printf 'OPENWEBUI_PRIVATE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.openwebui_private.app.homelab_test_user')"
    printf 'OPENWEBUI_PRIVATE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.openwebui_private.apache.status_user')"
    printf 'OPENWEBUI_PRIVATE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.openwebui_private.apache.prometheus_user')"

    printf 'OPENSPEEDTEST__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.openspeedtest.apache.status_user')"
    printf 'OPENSPEEDTEST__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.openspeedtest.apache.prometheus_user')"

    printf 'PIHOLE_1_PRIMARY__PASSWORD=%s\n' "$(load_secret '.pihole_1_primary.app.admin_user')"
    printf 'PIHOLE_1_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_1_primary.app.prometheus_user')"
    printf 'PIHOLE_1_PRIMARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.pihole_1_primary.apache.status_user')"
    printf 'PIHOLE_1_PRIMARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_1_primary.apache.prometheus_user')"

    printf 'PIHOLE_1_SECONDARY__PASSWORD=%s\n' "$(load_secret '.pihole_1_secondary.app.admin_user')"
    printf 'PIHOLE_1_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_1_secondary.app.prometheus_user')"
    printf 'PIHOLE_1_SECONDARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.pihole_1_secondary.apache.status_user')"
    printf 'PIHOLE_1_SECONDARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_1_secondary.apache.prometheus_user')"

    printf 'PIHOLE_1_BLACKHOLE__PASSWORD=%s\n' "$(load_secret '.pihole_1_blackhole.app.admin_user')"
    printf 'PIHOLE_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_1_blackhole.app.prometheus_user')"
    printf 'PIHOLE_1_BLACKHOLE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.pihole_1_blackhole.apache.status_user')"
    printf 'PIHOLE_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_1_blackhole.apache.prometheus_user')"

    printf 'PIHOLE_2_PRIMARY__PASSWORD=%s\n' "$(load_secret '.pihole_2_primary.app.admin_user')"
    printf 'PIHOLE_2_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_2_primary.app.prometheus_user')"
    printf 'PIHOLE_2_PRIMARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.pihole_2_primary.apache.status_user')"
    printf 'PIHOLE_2_PRIMARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_2_primary.apache.prometheus_user')"

    printf 'PIHOLE_2_SECONDARY__PASSWORD=%s\n' "$(load_secret '.pihole_2_secondary.app.admin_user')"
    printf 'PIHOLE_2_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_2_secondary.app.prometheus_user')"
    printf 'PIHOLE_2_SECONDARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.pihole_2_secondary.apache.status_user')"
    printf 'PIHOLE_2_SECONDARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_2_secondary.apache.prometheus_user')"

    printf 'PIHOLE_2_BLACKHOLE__PASSWORD=%s\n' "$(load_secret '.pihole_2_blackhole.app.admin_user')"
    printf 'PIHOLE_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_2_blackhole.app.prometheus_user')"
    printf 'PIHOLE_2_BLACKHOLE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.pihole_2_blackhole.apache.status_user')"
    printf 'PIHOLE_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.pihole_2_blackhole.apache.prometheus_user')"

    printf 'PROMETHEUS__MATEJ_PASSWORD=%s\n' "$(load_secret '.prometheus.app.matej_user')"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.prometheus.app.homelab_viewer_user')"
    printf 'PROMETHEUS__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.prometheus.app.homelab_test_user')"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.prometheus.app.prometheus_user')"
    printf 'PROMETHEUS__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.prometheus.apache.status_user')"
    printf 'PROMETHEUS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.prometheus.apache.prometheus_user')"

    printf 'RENOVATEBOT__MATEJ_PASSWORD=%s\n' "$(load_secret '.renovatebot.app.matej_user')"
    printf 'RENOVATEBOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.renovatebot.app.homelab_viewer_user')"
    printf 'RENOVATEBOT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.renovatebot.app.homelab_test_user')"
    printf 'RENOVATEBOT__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.renovatebot.apache.status_user')"
    printf 'RENOVATEBOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.renovatebot.apache.prometheus_user')"

    printf 'SAMBA_DATA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.samba_data.app.prometheus_user')"
    printf 'SAMBA_DATA__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.samba_data.apache.status_user')"
    printf 'SAMBA_DATA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.samba_data.apache.prometheus_user')"

    printf 'SMTP4DEV__MATEJ_PASSWORD=%s\n' "$(load_secret '.smtp4dev.app.matej_user')"
    printf 'SMTP4DEV__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.smtp4dev.app.homelab_viewer_user')"
    printf 'SMTP4DEV__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.smtp4dev.app.homelab_test_user')"
    printf 'SMTP4DEV__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.smtp4dev.apache.status_user')"
    printf 'SMTP4DEV__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.smtp4dev.apache.prometheus_user')"

    printf 'SPEEDTESTTRACKER__MATEJ_PASSWORD=%s\n' "$(load_secret '.speedtesttracker.app.matej_user')"
    printf 'SPEEDTESTTRACKER__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.speedtesttracker.apache.status_user')"
    printf 'SPEEDTESTTRACKER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.speedtesttracker.apache.prometheus_user')"

    printf 'TVHEADEND__MATEJ_PASSWORD=%s\n' "$(load_secret '.tvheadend.app.matej_user')"
    printf 'TVHEADEND__STREAM_PASSWORD=%s\n' "$(load_secret '.tvheadend.app.stream_user')"
    printf 'TVHEADEND__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.tvheadend.app.homelab_test_user')"
    printf 'TVHEADEND__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.tvheadend.app.homelab_viewer_user')"
    printf 'TVHEADEND__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.tvheadend.apache.status_user')"
    printf 'TVHEADEND__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.tvheadend.apache.prometheus_user')"

    printf 'UNBOUND_1_DEFAULT__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_1_default.app.matej_user')"
    printf 'UNBOUND_1_DEFAULT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_1_default.app.homelab_viewer_user')"
    printf 'UNBOUND_1_DEFAULT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_1_default.app.homelab_test_user')"
    printf 'UNBOUND_1_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_default.app.prometheus_user')"
    printf 'UNBOUND_1_DEFAULT__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_default.apache.status_user')"
    printf 'UNBOUND_1_DEFAULT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_default.apache.prometheus_user')"

    printf 'UNBOUND_1_GUESTS__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_1_guests.app.matej_user')"
    printf 'UNBOUND_1_GUESTS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_1_guests.app.homelab_viewer_user')"
    printf 'UNBOUND_1_GUESTS__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_1_guests.app.homelab_test_user')"
    printf 'UNBOUND_1_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_guests.app.prometheus_user')"
    printf 'UNBOUND_1_GUESTS__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_guests.apache.status_user')"
    printf 'UNBOUND_1_GUESTS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_guests.apache.prometheus_user')"

    printf 'UNBOUND_1_IOT__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_1_iot.app.matej_user')"
    printf 'UNBOUND_1_IOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_1_iot.app.homelab_viewer_user')"
    printf 'UNBOUND_1_IOT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_1_iot.app.homelab_test_user')"
    printf 'UNBOUND_1_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_iot.app.prometheus_user')"
    printf 'UNBOUND_1_IOT__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_iot.apache.status_user')"
    printf 'UNBOUND_1_IOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_iot.apache.prometheus_user')"

    printf 'UNBOUND_1_MATEJ__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_1_matej.app.matej_user')"
    printf 'UNBOUND_1_MATEJ__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_1_matej.app.homelab_viewer_user')"
    printf 'UNBOUND_1_MATEJ__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_1_matej.app.homelab_test_user')"
    printf 'UNBOUND_1_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_matej.app.prometheus_user')"
    printf 'UNBOUND_1_MATEJ__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_matej.apache.status_user')"
    printf 'UNBOUND_1_MATEJ__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_matej.apache.prometheus_user')"

    printf 'UNBOUND_1_MONIKA__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_1_monika.app.matej_user')"
    printf 'UNBOUND_1_MONIKA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_1_monika.app.homelab_viewer_user')"
    printf 'UNBOUND_1_MONIKA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_1_monika.app.homelab_test_user')"
    printf 'UNBOUND_1_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_monika.app.prometheus_user')"
    printf 'UNBOUND_1_MONIKA__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_monika.apache.status_user')"
    printf 'UNBOUND_1_MONIKA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_monika.apache.prometheus_user')"

    printf 'UNBOUND_1_INTERNAL__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_1_internal.app.matej_user')"
    printf 'UNBOUND_1_INTERNAL__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_1_internal.app.homelab_viewer_user')"
    printf 'UNBOUND_1_INTERNAL__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_1_internal.app.homelab_test_user')"
    printf 'UNBOUND_1_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_internal.app.prometheus_user')"
    printf 'UNBOUND_1_INTERNAL__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_internal.apache.status_user')"
    printf 'UNBOUND_1_INTERNAL__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_internal.apache.prometheus_user')"

    printf 'UNBOUND_1_BLACKHOLE__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_1_blackhole.app.matej_user')"
    printf 'UNBOUND_1_BLACKHOLE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_1_blackhole.app.homelab_viewer_user')"
    printf 'UNBOUND_1_BLACKHOLE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_1_blackhole.app.homelab_test_user')"
    printf 'UNBOUND_1_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_blackhole.app.prometheus_user')"
    printf 'UNBOUND_1_BLACKHOLE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_blackhole.apache.status_user')"
    printf 'UNBOUND_1_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_1_blackhole.apache.prometheus_user')"

    printf 'UNBOUND_2_DEFAULT__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_2_default.app.matej_user')"
    printf 'UNBOUND_2_DEFAULT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_2_default.app.homelab_viewer_user')"
    printf 'UNBOUND_2_DEFAULT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_2_default.app.homelab_test_user')"
    printf 'UNBOUND_2_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_default.app.prometheus_user')"
    printf 'UNBOUND_2_DEFAULT__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_default.apache.status_user')"
    printf 'UNBOUND_2_DEFAULT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_default.apache.prometheus_user')"

    printf 'UNBOUND_2_GUESTS__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_2_guests.app.matej_user')"
    printf 'UNBOUND_2_GUESTS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_2_guests.app.homelab_viewer_user')"
    printf 'UNBOUND_2_GUESTS__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_2_guests.app.homelab_test_user')"
    printf 'UNBOUND_2_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_guests.app.prometheus_user')"
    printf 'UNBOUND_2_GUESTS__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_guests.apache.status_user')"
    printf 'UNBOUND_2_GUESTS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_guests.apache.prometheus_user')"

    printf 'UNBOUND_2_IOT__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_2_iot.app.matej_user')"
    printf 'UNBOUND_2_IOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_2_iot.app.homelab_viewer_user')"
    printf 'UNBOUND_2_IOT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_2_iot.app.homelab_test_user')"
    printf 'UNBOUND_2_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_iot.app.prometheus_user')"
    printf 'UNBOUND_2_IOT__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_iot.apache.status_user')"
    printf 'UNBOUND_2_IOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_iot.apache.prometheus_user')"

    printf 'UNBOUND_2_MATEJ__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_2_matej.app.matej_user')"
    printf 'UNBOUND_2_MATEJ__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_2_matej.app.homelab_viewer_user')"
    printf 'UNBOUND_2_MATEJ__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_2_matej.app.homelab_test_user')"
    printf 'UNBOUND_2_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_matej.app.prometheus_user')"
    printf 'UNBOUND_2_MATEJ__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_matej.apache.status_user')"
    printf 'UNBOUND_2_MATEJ__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_matej.apache.prometheus_user')"

    printf 'UNBOUND_2_MONIKA__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_2_monika.app.matej_user')"
    printf 'UNBOUND_2_MONIKA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_2_monika.app.homelab_viewer_user')"
    printf 'UNBOUND_2_MONIKA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_2_monika.app.homelab_test_user')"
    printf 'UNBOUND_2_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_monika.app.prometheus_user')"
    printf 'UNBOUND_2_MONIKA__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_monika.apache.status_user')"
    printf 'UNBOUND_2_MONIKA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_monika.apache.prometheus_user')"

    printf 'UNBOUND_2_INTERNAL__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_2_internal.app.matej_user')"
    printf 'UNBOUND_2_INTERNAL__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_2_internal.app.homelab_viewer_user')"
    printf 'UNBOUND_2_INTERNAL__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_2_internal.app.homelab_test_user')"
    printf 'UNBOUND_2_INTERNAL__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_internal.app.prometheus_user')"
    printf 'UNBOUND_2_INTERNAL__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_internal.apache.status_user')"
    printf 'UNBOUND_2_INTERNAL__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_internal.apache.prometheus_user')"

    printf 'UNBOUND_2_BLACKHOLE__MATEJ_PASSWORD=%s\n' "$(load_secret '.unbound_2_blackhole.app.matej_user')"
    printf 'UNBOUND_2_BLACKHOLE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unbound_2_blackhole.app.homelab_viewer_user')"
    printf 'UNBOUND_2_BLACKHOLE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unbound_2_blackhole.app.homelab_test_user')"
    printf 'UNBOUND_2_BLACKHOLE__PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_blackhole.app.prometheus_user')"
    printf 'UNBOUND_2_BLACKHOLE__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_blackhole.apache.status_user')"
    printf 'UNBOUND_2_BLACKHOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unbound_2_blackhole.apache.prometheus_user')"

    printf 'UNIFICONTROLLER__HOMELAB_ADMIN_PASSWORD=%s\n' "$(load_secret '.unificontroller.app.homelab_admin_user')"
    printf 'UNIFICONTROLLER__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.unificontroller.app.homelab_viewer_user')"
    printf 'UNIFICONTROLLER__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.unificontroller.app.homelab_test_user')"
    printf 'UNIFICONTROLLER__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.unificontroller.apache.status_user')"
    printf 'UNIFICONTROLLER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.unificontroller.apache.prometheus_user')"

    printf 'UPTIMEKUMA_1__MATEJ_PASSWORD=%s\n' "$(load_secret '.uptimekuma_1.app.matej_user')"
    printf 'UPTIMEKUMA_1__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.uptimekuma_1.apache.status_user')"
    printf 'UPTIMEKUMA_1__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.uptimekuma_1.apache.prometheus_user')"

    printf 'UPTIMEKUMA_2__MATEJ_PASSWORD=%s\n' "$(load_secret '.uptimekuma_2.app.matej_user')"
    printf 'UPTIMEKUMA_2__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.uptimekuma_2.apache.status_user')"
    printf 'UPTIMEKUMA_2__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.uptimekuma_2.apache.prometheus_user')"

    printf 'VAULTWARDEN__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.vaultwarden.app.homelab_test_user')"
    printf 'VAULTWARDEN__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.vaultwarden.apache.status_user')"
    printf 'VAULTWARDEN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.vaultwarden.apache.prometheus_user')"

    printf 'VIKUNJA__MATEJ_PASSWORD=%s\n' "$(load_secret '.vikunja.app.matej_user')"
    printf 'VIKUNJA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.vikunja.app.homelab_test_user')"
    printf 'VIKUNJA__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.vikunja.apache.status_user')"
    printf 'VIKUNJA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.vikunja.apache.prometheus_user')"

    printf 'WIKIPEDIA__MATEJ_PASSWORD=%s\n' "$(load_secret '.kiwix_wikipedia.app.matej_user')"
    printf 'WIKIPEDIA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.kiwix_wikipedia.app.homelab_viewer_user')"
    printf 'WIKIPEDIA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.kiwix_wikipedia.app.homelab_test_user')"
    printf 'WIKIPEDIA__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.kiwix_wikipedia.apache.status_user')"
    printf 'WIKIPEDIA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.kiwix_wikipedia.apache.prometheus_user')"

    printf 'WIKTIONARY__MATEJ_PASSWORD=%s\n' "$(load_secret '.kiwix_wiktionary.app.matej_user')"
    printf 'WIKTIONARY__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_secret '.kiwix_wiktionary.app.homelab_viewer_user')"
    printf 'WIKTIONARY__HOMELAB_TEST_PASSWORD=%s\n' "$(load_secret '.kiwix_wiktionary.app.homelab_test_user')"
    printf 'WIKTIONARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_secret '.kiwix_wiktionary.apache.status_user')"
    printf 'WIKTIONARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_secret '.kiwix_wiktionary.apache.prometheus_user')"
} >>'.secrets.env'

chmod 0400 '.secrets.env'
