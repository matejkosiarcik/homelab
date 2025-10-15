#!/bin/sh
set -euf

cd "$(dirname "$0")"

if [ "${BW_SESSION-}" = '' ]; then
    echo 'You must set BW_SESSION env variable before calling this script.' >&2
    exit 1
fi

bw sync                  # Sync latest changes
bw list items >/dev/null # Verify we can access Vaultwarden

rm -f .secrets.env

load_password() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    bw list items --search "homelab--$1--$2--$3" | jq -er ".[] | select(.name == \"homelab--$1--$2--$3\").login.password"
}

{
    printf 'ACTUALBUDGET_PASSWORD=%s\n' "$(load_password actualbudget app admin)"
    printf 'ACTUALBUDGET_ENCRYPTION_PASSWORD=%s\n' "$(load_password actualbudget app encryption)"
    printf 'ACTUALBUDGET_SYNC_ID=%s\n' "$(load_password actualbudget app sync-id)"
    printf 'ACTUALBUDGET_PROXY_STATUS_PASSWORD=%s\n' "$(load_password actualbudget apache status)"
    printf 'ACTUALBUDGET_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password actualbudget apache prometheus)"

    printf 'CERTBOT_MATEJ_PASSWORD=%s\n' "$(load_password certbot app matej)"
    printf 'CERTBOT_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password certbot app homelab-viewer)"
    printf 'CERTBOT_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password certbot app homelab-test)"
    printf 'CERTBOT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password certbot apache status)"
    printf 'CERTBOT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password certbot apache prometheus)"

    printf 'CHANGEDETECTION_ADMIN_PASSWORD=%s\n' "$(load_password changedetection app admin)"
    printf 'CHANGEDETECTION_PROXY_STATUS_PASSWORD=%s\n' "$(load_password changedetection apache status)"
    printf 'CHANGEDETECTION_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password changedetection apache prometheus)"

    printf 'DAWARICH_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password dawarich app homelab-test)"
    printf 'DAWARICH_PROXY_STATUS_PASSWORD=%s\n' "$(load_password dawarich apache status)"
    printf 'DAWARICH_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password dawarich apache prometheus)"
    printf 'DAWARICH_PROMETHEUS_PASSWORD=%s\n' "$(load_password dawarich app prometheus)"

    printf 'DOCKER_CACHE_PROXY_DOCKERHUB_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-cache-proxy-dockerhub apache status)"
    printf 'DOCKER_CACHE_PROXY_DOCKERHUB_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-cache-proxy-dockerhub apache prometheus)"

    # printf 'DOCKER_STATS_MACBOOK_PRO_2012_MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-macbook-pro-2012 app matej)"
    # printf 'DOCKER_STATS_MACBOOK_PRO_2012_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-macbook-pro-2012 app homelab-viewer)"
    # printf 'DOCKER_STATS_MACBOOK_PRO_2012_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-macbook-pro-2012 app homelab-test)"
    # printf 'DOCKER_STATS_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-macbook-pro-2012 app prometheus)"
    # printf 'DOCKER_STATS_MACBOOK_PRO_2012_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-macbook-pro-2012 apache status)"
    # printf 'DOCKER_STATS_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-macbook-pro-2012 apache prometheus)"

    printf 'DOCKER_STATS_ODROID_H3_MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app matej)"
    printf 'DOCKER_STATS_ODROID_H3_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app homelab-viewer)"
    printf 'DOCKER_STATS_ODROID_H3_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app homelab-test)"
    printf 'DOCKER_STATS_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app prometheus)"
    printf 'DOCKER_STATS_ODROID_H3_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 apache status)"
    printf 'DOCKER_STATS_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 apache prometheus)"

    printf 'DOCKER_STATS_ODROID_H4_ULTRA_MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app matej)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app homelab-viewer)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app homelab-test)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app prometheus)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra apache status)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra apache prometheus)"

    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b app matej)"
    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b app homelab-viewer)"
    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b app homelab-test)"
    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b app prometheus)"
    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b apache status)"
    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b apache prometheus)"

    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app matej)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app homelab-viewer)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app homelab-test)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app prometheus)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g apache status)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g apache prometheus)"

    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app matej)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app homelab-viewer)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app homelab-test)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app prometheus)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g apache status)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g apache prometheus)"

    printf 'DOZZLE_ADMIN_PASSWORD=%s\n' "$(load_password dozzle app admin)"
    printf 'DOZZLE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password dozzle apache status)"
    printf 'DOZZLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password dozzle apache prometheus)"

    printf 'GATUS_1_MATEJ_PASSWORD=%s\n' "$(load_password gatus-1 app matej)"
    printf 'GATUS_1_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password gatus-1 app homelab-viewer)"
    printf 'GATUS_1_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password gatus-1 app homelab-test)"
    printf 'GATUS_1_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-1 app prometheus)"
    printf 'GATUS_1_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-1 apache status)"
    printf 'GATUS_1_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-1 apache prometheus)"

    printf 'GATUS_2_MATEJ_PASSWORD=%s\n' "$(load_password gatus-2 app matej)"
    printf 'GATUS_2_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password gatus-2 app homelab-viewer)"
    printf 'GATUS_2_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password gatus-2 app homelab-test)"
    printf 'GATUS_2_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 app prometheus)"
    printf 'GATUS_2_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-2 apache status)"
    printf 'GATUS_2_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 apache prometheus)"

    printf 'GOTIFY_ADMIN_PASSWORD=%s\n' "$(load_password gotify app admin)"
    printf 'GOTIFY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gotify apache status)"
    printf 'GOTIFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gotify apache prometheus)"

    printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$(load_password grafana app admin)"
    # TODO: printf 'GRAFANA_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password grafana app homelab-test)"
    printf 'GRAFANA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password grafana apache status)"
    printf 'GRAFANA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password grafana apache prometheus)"

    printf 'GROCERIES_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password groceries app homelab-test)"
    printf 'GROCERIES_PROXY_STATUS_PASSWORD=%s\n' "$(load_password groceries apache status)"
    printf 'GROCERIES_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password groceries apache prometheus)"

    printf 'HEALTHCHECKS_MATEJ_PASSWORD=%s\n' "$(load_password healthchecks app matej)"
    printf 'HEALTHCHECKS_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password healthchecks app homelab-test)"
    printf 'HEALTHCHECKS_API_KEY_READONLY=%s\n' "$(load_password healthchecks app api-key-readonly)"
    printf 'HEALTHCHECKS_API_KEY_READWRITE=%s\n' "$(load_password healthchecks app api-key-readwrite)"
    printf 'HEALTHCHECKS_PING_KEY=%s\n' "$(load_password healthchecks app ping-key)"
    printf 'HEALTHCHECKS_PROMETHEUS_PROJECT=%s\n' "$(load_password healthchecks app project-id)"
    printf 'HEALTHCHECKS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password healthchecks apache status)"
    printf 'HEALTHCHECKS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password healthchecks apache prometheus)"

    printf 'HOMEASSISTANT_MATEJ_PASSWORD=%s\n' "$(load_password homeassistant app matej)"
    printf 'HOMEASSISTANT_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password homeassistant app homelab-viewer)"
    printf 'HOMEASSISTANT_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password homeassistant app homelab-test)"
    printf 'HOMEASSISTANT_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password homeassistant app homelab-viewer-api-key)"
    printf 'HOMEASSISTANT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password homeassistant apache status)"
    printf 'HOMEASSISTANT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password homeassistant apache prometheus)"

    printf 'HOMEPAGE_MATEJ_PASSWORD=%s\n' "$(load_password homepage app matej)"
    printf 'HOMEPAGE_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password homepage app homelab-viewer)"
    printf 'HOMEPAGE_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password homepage app homelab-test)"
    printf 'HOMEPAGE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password homepage apache status)"
    printf 'HOMEPAGE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password homepage apache prometheus)"

    printf 'JELLYFIN_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password jellyfin app homelab-viewer)"
    printf 'JELLYFIN_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password jellyfin app homelab-test)"
    printf 'JELLYFIN_PROMETHEUS_PASSWORD=%s\n' "$(load_password jellyfin app prometheus)"
    printf 'JELLYFIN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password jellyfin apache status)"
    printf 'JELLYFIN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password jellyfin apache prometheus)"

    printf 'MINIO_MATEJ_PASSWORD=%s\n' "$(load_password minio app matej)"
    printf 'MINIO_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password minio app homelab-viewer)"
    printf 'MINIO_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password minio app homelab-test)"
    printf 'MINIO_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password minio app prometheus-token)"
    printf 'MINIO_PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio apache status)"
    printf 'MINIO_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password minio apache prometheus)"
    printf 'MINIO_CONSOLE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio apache status)"
    printf 'MINIO_CONSOLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password minio apache prometheus)"

    printf 'MOTIONEYE_KITCHEN_ADMIN_PASSWORD=%s\n' "$(load_password motioneye-kitchen app admin)"
    printf 'MOTIONEYE_KITCHEN_STREAM_PASSWORD=%s\n' "$(load_password motioneye-kitchen app stream)"
    printf 'MOTIONEYE_KITCHEN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password motioneye-kitchen apache status)"
    printf 'MOTIONEYE_KITCHEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password motioneye-kitchen apache prometheus)"

    printf 'NODEEXPORTER_MACBOOK_PRO_2012_MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-macbook-pro-2012 app matej)"
    printf 'NODEEXPORTER_MACBOOK_PRO_2012_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-macbook-pro-2012 app homelab-viewer)"
    printf 'NODEEXPORTER_MACBOOK_PRO_2012_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-macbook-pro-2012 app homelab-test)"
    printf 'NODEEXPORTER_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-macbook-pro-2012 app prometheus)"
    printf 'NODEEXPORTER_MACBOOK_PRO_2012_PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-macbook-pro-2012 apache status)"
    printf 'NODEEXPORTER_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-macbook-pro-2012 apache prometheus)"

    printf 'NODEEXPORTER_ODROID_H3_MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 app matej)"
    printf 'NODEEXPORTER_ODROID_H3_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 app homelab-viewer)"
    printf 'NODEEXPORTER_ODROID_H3_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 app homelab-test)"
    printf 'NODEEXPORTER_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 app prometheus)"
    printf 'NODEEXPORTER_ODROID_H3_PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 apache status)"
    printf 'NODEEXPORTER_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 apache prometheus)"

    printf 'NODEEXPORTER_ODROID_H4_ULTRA_MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra app matej)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra app homelab-viewer)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra app homelab-test)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra app prometheus)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra apache status)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra apache prometheus)"

    printf 'NODEEXPORTER_RASPBERRY_PI_3B_MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-3b app matej)"
    printf 'NODEEXPORTER_RASPBERRY_PI_3B_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-3b app homelab-viewer)"
    printf 'NODEEXPORTER_RASPBERRY_PI_3B_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-3b app homelab-test)"
    printf 'NODEEXPORTER_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-3b app prometheus)"
    printf 'NODEEXPORTER_RASPBERRY_PI_3B_PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-3b apache status)"
    printf 'NODEEXPORTER_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-3b apache prometheus)"

    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G_MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g app matej)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g app homelab-viewer)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g app homelab-test)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g app prometheus)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g apache status)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g apache prometheus)"

    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G_MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g app matej)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g app homelab-viewer)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g app homelab-test)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g app prometheus)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g apache status)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g apache prometheus)"

    printf 'NTFY_ADMIN_PASSWORD=%s\n' "$(load_password ntfy app admin)"
    printf 'NTFY_USER_PASSWORD=%s\n' "$(load_password ntfy app user)"
    printf 'NTFY_PUBLISHER_PASSWORD=%s\n' "$(load_password ntfy app publisher)"
    printf 'NTFY_PUBLISHER_TOKEN=%s\n' "$(load_password ntfy app publisher-token)"
    printf 'NTFY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password ntfy apache status)"
    printf 'NTFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ntfy apache prometheus)"

    printf 'NETALERTX_ADMIN_PASSWORD=%s\n' "$(load_password netalertx app admin)"
    printf 'NETALERTX_PROMETHEUS_PASSWORD=%s\n' "$(load_password netalertx app prometheus)"
    printf 'NETALERTX_PROXY_STATUS_PASSWORD=%s\n' "$(load_password ntfy apache status)"
    printf 'NETALERTX_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ntfy apache prometheus)"

    printf 'OLLAMA_MATEJ_PASSWORD=%s\n' "$(load_password ollama app matej)"
    printf 'OLLAMA_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password ollama app homelab-viewer)"
    printf 'OLLAMA_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password ollama app homelab-test)"
    printf 'OLLAMA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password ollama apache status)"
    printf 'OLLAMA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ollama apache prometheus)"

    printf 'OLLAMA_PRIVATE_MATEJ_PASSWORD=%s\n' "$(load_password ollama-private app matej)"
    printf 'OLLAMA_PRIVATE_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password ollama-private app homelab-viewer)"
    printf 'OLLAMA_PRIVATE_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password ollama-private app homelab-test)"
    printf 'OLLAMA_PRIVATE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password ollama-private apache status)"
    printf 'OLLAMA_PRIVATE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ollama-private apache prometheus)"

    printf 'OMADACONTROLLER_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password omadacontroller app homelab-viewer)"
    printf 'OMADACONTROLLER_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password omadacontroller app homelab-test)"
    printf 'OMADACONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password omadacontroller apache status)"
    printf 'OMADACONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password omadacontroller apache prometheus)"

    printf 'OPENWEBUI_MATEJ_PASSWORD=%s\n' "$(load_password openwebui app matej)"
    printf 'OPENWEBUI_PROXY_STATUS_PASSWORD=%s\n' "$(load_password openwebui apache status)"
    printf 'OPENWEBUI_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password openwebui apache prometheus)"

    printf 'OPENWEBUI_PRIVATE_MATEJ_PASSWORD=%s\n' "$(load_password openwebui-private app matej)"
    printf 'OPENWEBUI_PRIVATE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password openwebui-private apache status)"
    printf 'OPENWEBUI_PRIVATE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password openwebui-private apache prometheus)"

    printf 'OPENSPEEDTEST_PROXY_STATUS_PASSWORD=%s\n' "$(load_password openspeedtest apache status)"
    printf 'OPENSPEEDTEST_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password openspeedtest apache prometheus)"

    printf 'OWNTRACKS_ADMIN_PASSWORD=%s\n' "$(load_password owntracks app admin)"
    printf 'OWNTRACKS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password owntracks apache status)"
    printf 'OWNTRACKS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password owntracks apache prometheus)"

    printf 'PIHOLE_1_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-1-primary app admin)"
    printf 'PIHOLE_1_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-primary app prometheus)"
    printf 'PIHOLE_1_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-primary apache status)"
    printf 'PIHOLE_1_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-primary apache prometheus)"

    printf 'PIHOLE_1_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-1-secondary app admin)"
    printf 'PIHOLE_1_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary app prometheus)"
    printf 'PIHOLE_1_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary apache status)"
    printf 'PIHOLE_1_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary apache prometheus)"

    printf 'PIHOLE_2_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-2-primary app admin)"
    printf 'PIHOLE_2_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-primary app prometheus)"
    printf 'PIHOLE_2_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-primary apache status)"
    printf 'PIHOLE_2_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-primary apache prometheus)"

    printf 'PIHOLE_2_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-2-secondary app admin)"
    printf 'PIHOLE_2_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary app prometheus)"
    printf 'PIHOLE_2_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary apache status)"
    printf 'PIHOLE_2_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary apache prometheus)"

    printf 'PROMETHEUS_MATEJ_PASSWORD=%s\n' "$(load_password prometheus app matej)"
    printf 'PROMETHEUS_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password prometheus app homelab-viewer)"
    printf 'PROMETHEUS_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password prometheus app homelab-test)"
    printf 'PROMETHEUS_PROMETHEUS_PASSWORD=%s\n' "$(load_password prometheus app prometheus)"
    printf 'PROMETHEUS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password prometheus apache status)"
    printf 'PROMETHEUS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password prometheus apache prometheus)"

    printf 'RENOVATEBOT_MATEJ_PASSWORD=%s\n' "$(load_password renovatebot app matej)"
    printf 'RENOVATEBOT_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password renovatebot app homelab-viewer)"
    printf 'RENOVATEBOT_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password renovatebot app homelab-test)"
    printf 'RENOVATEBOT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password renovatebot apache status)"
    printf 'RENOVATEBOT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password renovatebot apache prometheus)"

    printf 'SMTP4DEV_MATEJ_PASSWORD=%s\n' "$(load_password smtp4dev app matej)"
    printf 'SMTP4DEV_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password smtp4dev app homelab-viewer)"
    printf 'SMTP4DEV_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password smtp4dev app homelab-test)"
    printf 'SMTP4DEV_PROXY_STATUS_PASSWORD=%s\n' "$(load_password smtp4dev apache status)"
    printf 'SMTP4DEV_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password smtp4dev apache prometheus)"

    printf 'SPEEDTESTTRACKER_MATEJ_PASSWORD=%s\n' "$(load_password speedtesttracker app matej)"
    printf 'SPEEDTESTTRACKER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password speedtesttracker apache status)"
    printf 'SPEEDTESTTRACKER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password speedtesttracker apache prometheus)"

    printf 'TVHEADEND_MATEJ_PASSWORD=%s\n' "$(load_password tvheadend app matej)"
    printf 'TVHEADEND_HOMELAB_STREAM_PASSWORD=%s\n' "$(load_password tvheadend app homelab-stream)"
    printf 'TVHEADEND_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password tvheadend app homelab-test)"
    printf 'TVHEADEND_PROXY_STATUS_PASSWORD=%s\n' "$(load_password tvheadend apache status)"
    printf 'TVHEADEND_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password tvheadend apache prometheus)"

    printf 'UNBOUND_1_DEFAULT_MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-default app matej)"
    printf 'UNBOUND_1_DEFAULT_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-default app homelab-viewer)"
    printf 'UNBOUND_1_DEFAULT_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-default app homelab-test)"
    printf 'UNBOUND_1_DEFAULT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-default app prometheus)"
    printf 'UNBOUND_1_DEFAULT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-default apache status)"
    printf 'UNBOUND_1_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-default apache prometheus)"

    printf 'UNBOUND_1_MATEJ_MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-matej app matej)"
    printf 'UNBOUND_1_MATEJ_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-matej app homelab-viewer)"
    printf 'UNBOUND_1_MATEJ_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-matej app homelab-test)"
    printf 'UNBOUND_1_MATEJ_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-matej app prometheus)"
    printf 'UNBOUND_1_MATEJ_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-matej apache status)"
    printf 'UNBOUND_1_MATEJ_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-matej apache prometheus)"

    printf 'UNBOUND_1_MONIKA_MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-monika app matej)"
    printf 'UNBOUND_1_MONIKA_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-monika app homelab-viewer)"
    printf 'UNBOUND_1_MONIKA_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-monika app homelab-test)"
    printf 'UNBOUND_1_MONIKA_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-monika app prometheus)"
    printf 'UNBOUND_1_MONIKA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-monika apache status)"
    printf 'UNBOUND_1_MONIKA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-monika apache prometheus)"

    printf 'UNBOUND_1_IOT_MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-iot app matej)"
    printf 'UNBOUND_1_IOT_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-iot app homelab-viewer)"
    printf 'UNBOUND_1_IOT_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-iot app homelab-test)"
    printf 'UNBOUND_1_IOT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-iot app prometheus)"
    printf 'UNBOUND_1_IOT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-iot apache status)"
    printf 'UNBOUND_1_IOT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-iot apache prometheus)"

    printf 'UNBOUND_1_GUESTS_MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-guests app matej)"
    printf 'UNBOUND_1_GUESTS_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-guests app homelab-viewer)"
    printf 'UNBOUND_1_GUESTS_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-guests app homelab-test)"
    printf 'UNBOUND_1_GUESTS_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-guests app prometheus)"
    printf 'UNBOUND_1_GUESTS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-guests apache status)"
    printf 'UNBOUND_1_GUESTS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-guests apache prometheus)"

    printf 'UNBOUND_2_DEFAULT_MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-default app matej)"
    printf 'UNBOUND_2_DEFAULT_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-default app homelab-viewer)"
    printf 'UNBOUND_2_DEFAULT_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-default app homelab-test)"
    printf 'UNBOUND_2_DEFAULT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-default app prometheus)"
    printf 'UNBOUND_2_DEFAULT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-default apache status)"
    printf 'UNBOUND_2_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-default apache prometheus)"

    printf 'UNBOUND_2_MATEJ_MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-matej app matej)"
    printf 'UNBOUND_2_MATEJ_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-matej app homelab-viewer)"
    printf 'UNBOUND_2_MATEJ_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-matej app homelab-test)"
    printf 'UNBOUND_2_MATEJ_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-matej app prometheus)"
    printf 'UNBOUND_2_MATEJ_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-matej apache status)"
    printf 'UNBOUND_2_MATEJ_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-matej apache prometheus)"

    printf 'UNBOUND_2_MONIKA_MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-monika app matej)"
    printf 'UNBOUND_2_MONIKA_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-monika app homelab-viewer)"
    printf 'UNBOUND_2_MONIKA_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-monika app homelab-test)"
    printf 'UNBOUND_2_MONIKA_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-monika app prometheus)"
    printf 'UNBOUND_2_MONIKA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-monika apache status)"
    printf 'UNBOUND_2_MONIKA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-monika apache prometheus)"

    printf 'UNBOUND_2_IOT_MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-iot app matej)"
    printf 'UNBOUND_2_IOT_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-iot app homelab-viewer)"
    printf 'UNBOUND_2_IOT_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-iot app homelab-test)"
    printf 'UNBOUND_2_IOT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-iot app prometheus)"
    printf 'UNBOUND_2_IOT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-iot apache status)"
    printf 'UNBOUND_2_IOT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-iot apache prometheus)"

    printf 'UNBOUND_2_GUESTS_MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-guests app matej)"
    printf 'UNBOUND_2_GUESTS_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-guests app homelab-viewer)"
    printf 'UNBOUND_2_GUESTS_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-guests app homelab-test)"
    printf 'UNBOUND_2_GUESTS_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-guests app prometheus)"
    printf 'UNBOUND_2_GUESTS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-guests apache status)"
    printf 'UNBOUND_2_GUESTS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-guests apache prometheus)"

    printf 'UNIFICONTROLLER_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unificontroller app homelab-viewer)"
    printf 'UNIFICONTROLLER_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unificontroller app homelab-test)"
    printf 'UNIFICONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unificontroller apache status)"
    printf 'UNIFICONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unificontroller apache prometheus)"

    printf 'UPTIMEKUMA_MATEJ_PASSWORD=%s\n' "$(load_password uptimekuma app matej)"
    printf 'UPTIMEKUMA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password uptimekuma apache status)"
    printf 'UPTIMEKUMA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password uptimekuma apache prometheus)"

    printf 'VAULTWARDEN_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password vaultwarden app homelab-test)"
    printf 'VAULTWARDEN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password vaultwarden apache status)"
    printf 'VAULTWARDEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password vaultwarden apache prometheus)"

    printf 'VIKUNJA_MATEJ_PASSWORD=%s\n' "$(load_password vikunja app matej)"
    printf 'VIKUNJA_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password vikunja app homelab-viewer)"
    printf 'VIKUNJA_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password vikunja app homelab-test)"
    printf 'VIKUNJA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password vikunja apache status)"
    printf 'VIKUNJA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password vikunja apache prometheus)"

    printf 'WIKIPEDIA_MATEJ_PASSWORD=%s\n' "$(load_password kiwix-wikipedia app matej)"
    printf 'WIKIPEDIA_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password kiwix-wikipedia app homelab-viewer)"
    printf 'WIKIPEDIA_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password kiwix-wikipedia app homelab-test)"
    printf 'WIKIPEDIA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password kiwix-wikipedia apache status)"
    printf 'WIKIPEDIA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password kiwix-wikipedia apache prometheus)"

    printf 'WIKTIONARY_MATEJ_PASSWORD=%s\n' "$(load_password kiwix-wiktionary app matej)"
    printf 'WIKTIONARY_HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password kiwix-wiktionary app homelab-viewer)"
    printf 'WIKTIONARY_HOMELAB_TEST_PASSWORD=%s\n' "$(load_password kiwix-wiktionary app homelab-test)"
    printf 'WIKTIONARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password kiwix-wiktionary apache status)"
    printf 'WIKTIONARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password kiwix-wiktionary apache prometheus)"
} >>'.secrets.env'

chmod 0400 '.secrets.env'
