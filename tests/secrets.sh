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

    itemname="$(printf '%s--%s--%s' "$1" "$2" "$3" | tr '-' '_')"
    bw list items --search "$itemname" | jq -er ".[] | select(.name == \"$itemname\").login.password"
}

{
    printf 'ACTUALBUDGET__PASSWORD=%s\n' "$(load_password actualbudget app admin)"
    printf 'ACTUALBUDGET__ENCRYPTION_PASSWORD=%s\n' "$(load_password actualbudget app encryption)"
    printf 'ACTUALBUDGET__SYNC_ID=%s\n' "$(load_password actualbudget app sync-id)"
    printf 'ACTUALBUDGET__PROXY_STATUS_PASSWORD=%s\n' "$(load_password actualbudget apache status)"
    printf 'ACTUALBUDGET__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password actualbudget apache prometheus)"

    printf 'CERTBOT__MATEJ_PASSWORD=%s\n' "$(load_password certbot app matej)"
    printf 'CERTBOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password certbot app homelab-viewer)"
    printf 'CERTBOT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password certbot app homelab-test)"
    printf 'CERTBOT__PROXY_STATUS_PASSWORD=%s\n' "$(load_password certbot apache status)"
    printf 'CERTBOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password certbot apache prometheus)"

    printf 'CHANGEDETECTION__ADMIN_PASSWORD=%s\n' "$(load_password changedetection app admin)"
    printf 'CHANGEDETECTION__PROXY_STATUS_PASSWORD=%s\n' "$(load_password changedetection apache status)"
    printf 'CHANGEDETECTION__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password changedetection apache prometheus)"

    printf 'DAWARICH__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password dawarich app homelab-test)"
    printf 'DAWARICH__PROXY_STATUS_PASSWORD=%s\n' "$(load_password dawarich apache status)"
    printf 'DAWARICH__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password dawarich apache prometheus)"
    printf 'DAWARICH__PROMETHEUS_PASSWORD=%s\n' "$(load_password dawarich app prometheus)"

    printf 'DOCKER_CACHE_PROXY_DOCKERHUB__PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-cache-proxy-dockerhub apache status)"
    printf 'DOCKER_CACHE_PROXY_DOCKERHUB__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-cache-proxy-dockerhub apache prometheus)"

    printf 'DOCKER_STATS_ODROID_H3__MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app matej)"
    printf 'DOCKER_STATS_ODROID_H3__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app homelab-viewer)"
    printf 'DOCKER_STATS_ODROID_H3__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app homelab-test)"
    printf 'DOCKER_STATS_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app prometheus)"
    printf 'DOCKER_STATS_ODROID_H3__PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 apache status)"
    printf 'DOCKER_STATS_ODROID_H3__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 apache prometheus)"

    printf 'DOCKER_STATS_ODROID_H4_ULTRA__MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app matej)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app homelab-viewer)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app homelab-test)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app prometheus)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra apache status)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra apache prometheus)"

    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app matej)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app homelab-viewer)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app homelab-test)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app prometheus)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g apache status)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g apache prometheus)"

    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__MATEJ_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app matej)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app homelab-viewer)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app homelab-test)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app prometheus)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g apache status)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g apache prometheus)"

    printf 'DOZZLE__MATEJ_PASSWORD=%s\n' "$(load_password dozzle app matej)"
    printf 'DOZZLE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password dozzle app homelab-test)"
    printf 'DOZZLE__PROXY_STATUS_PASSWORD=%s\n' "$(load_password dozzle apache status)"
    printf 'DOZZLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password dozzle apache prometheus)"

    printf 'GATUS_1__MATEJ_PASSWORD=%s\n' "$(load_password gatus-1 app matej)"
    printf 'GATUS_1__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password gatus-1 app homelab-viewer)"
    printf 'GATUS_1__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password gatus-1 app homelab-test)"
    printf 'GATUS_1__PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-1 app prometheus)"
    printf 'GATUS_1__PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-1 apache status)"
    printf 'GATUS_1__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-1 apache prometheus)"

    printf 'GATUS_2__MATEJ_PASSWORD=%s\n' "$(load_password gatus-2 app matej)"
    printf 'GATUS_2__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password gatus-2 app homelab-viewer)"
    printf 'GATUS_2__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password gatus-2 app homelab-test)"
    printf 'GATUS_2__PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 app prometheus)"
    printf 'GATUS_2__PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-2 apache status)"
    printf 'GATUS_2__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 apache prometheus)"

    printf 'GOTIFY__MATEJ_PASSWORD=%s\n' "$(load_password gotify app matej)"
    printf 'GOTIFY__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password gotify app homelab-test)"
    printf 'GOTIFY__PROXY_STATUS_PASSWORD=%s\n' "$(load_password gotify apache status)"
    printf 'GOTIFY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gotify apache prometheus)"

    printf 'GRAFANA__MATEJ_PASSWORD=%s\n' "$(load_password grafana app matej)"
    printf 'GRAFANA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password grafana app homelab-viewer)"
    printf 'GRAFANA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password grafana app homelab-test)"
    printf 'GRAFANA__PROXY_STATUS_PASSWORD=%s\n' "$(load_password grafana apache status)"
    printf 'GRAFANA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password grafana apache prometheus)"

    printf 'GROCERIES__HOMELABTEST_PASSWORD=%s\n' "$(load_password groceries app homelab-test)"
    printf 'GROCERIES__PROXY_STATUS_PASSWORD=%s\n' "$(load_password groceries apache status)"
    printf 'GROCERIES__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password groceries apache prometheus)"

    printf 'HEALTHCHECKS__MATEJ_PASSWORD=%s\n' "$(load_password healthchecks app matej)"
    printf 'HEALTHCHECKS__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password healthchecks app homelab-test)"
    printf 'HEALTHCHECKS__API_KEY_READONLY=%s\n' "$(load_password healthchecks app api-key-readonly)"
    printf 'HEALTHCHECKS__API_KEY_READWRITE=%s\n' "$(load_password healthchecks app api-key-readwrite)"
    printf 'HEALTHCHECKS__PING_KEY=%s\n' "$(load_password healthchecks app ping-key)"
    printf 'HEALTHCHECKS__PROMETHEUS_PROJECT=%s\n' "$(load_password healthchecks app project-id)"
    printf 'HEALTHCHECKS__PROXY_STATUS_PASSWORD=%s\n' "$(load_password healthchecks apache status)"
    printf 'HEALTHCHECKS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password healthchecks apache prometheus)"

    printf 'HOMEASSISTANT__MATEJ_PASSWORD=%s\n' "$(load_password homeassistant app matej)"
    printf 'HOMEASSISTANT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password homeassistant app homelab-viewer)"
    printf 'HOMEASSISTANT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password homeassistant app homelab-test)"
    printf 'HOMEASSISTANT__PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password homeassistant app homelab-viewer-api-key)"
    printf 'HOMEASSISTANT__PROXY_STATUS_PASSWORD=%s\n' "$(load_password homeassistant apache status)"
    printf 'HOMEASSISTANT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password homeassistant apache prometheus)"

    printf 'HOMEPAGE__MATEJ_PASSWORD=%s\n' "$(load_password homepage app matej)"
    printf 'HOMEPAGE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password homepage app homelab-viewer)"
    printf 'HOMEPAGE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password homepage app homelab-test)"
    printf 'HOMEPAGE__PROXY_STATUS_PASSWORD=%s\n' "$(load_password homepage apache status)"
    printf 'HOMEPAGE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password homepage apache prometheus)"

    printf 'JELLYFIN__MATEJ_PASSWORD=%s\n' "$(load_password jellyfin app matej)"
    printf 'JELLYFIN__MONIKA_PASSWORD=%s\n' "$(load_password jellyfin app monika)"
    printf 'JELLYFIN__HOMELAB_ADMIN_PASSWORD=%s\n' "$(load_password jellyfin app homelab-admin)"
    printf 'JELLYFIN__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password jellyfin app homelab-test)"
    printf 'JELLYFIN__PROMETHEUS_PASSWORD=%s\n' "$(load_password jellyfin app prometheus)"
    printf 'JELLYFIN__PROXY_STATUS_PASSWORD=%s\n' "$(load_password jellyfin apache status)"
    printf 'JELLYFIN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password jellyfin apache prometheus)"

    printf 'MINIO__MATEJ_PASSWORD=%s\n' "$(load_password minio app matej)"
    printf 'MINIO__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password minio app homelab-viewer)"
    printf 'MINIO__HOMELAB_WRITER_PASSWORD=%s\n' "$(load_password minio app homelab-writer)"
    printf 'MINIO__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password minio app homelab-test)"
    printf 'MINIO__PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password minio app prometheus-token)"
    printf 'MINIO__PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio apache status)"
    printf 'MINIO__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password minio apache prometheus)"
    printf 'MINIO_CONSOLE__PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio apache status)"
    printf 'MINIO_CONSOLE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password minio apache prometheus)"

    printf 'MOTIONEYE_KITCHEN__ADMIN_PASSWORD=%s\n' "$(load_password motioneye-kitchen app admin)"
    printf 'MOTIONEYE_KITCHEN__HOMELAB_STREAM_PASSWORD=%s\n' "$(load_password motioneye-kitchen app homelab-stream)"
    printf 'MOTIONEYE_KITCHEN__PROXY_STATUS_PASSWORD=%s\n' "$(load_password motioneye-kitchen apache status)"
    printf 'MOTIONEYE_KITCHEN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password motioneye-kitchen apache prometheus)"

    printf 'NODEEXPORTER_ODROID_H3__MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 app matej)"
    printf 'NODEEXPORTER_ODROID_H3__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 app homelab-viewer)"
    printf 'NODEEXPORTER_ODROID_H3__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 app homelab-test)"
    printf 'NODEEXPORTER_ODROID_H3__PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 app prometheus)"
    printf 'NODEEXPORTER_ODROID_H3__PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 apache status)"
    printf 'NODEEXPORTER_ODROID_H3__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h3 apache prometheus)"

    printf 'NODEEXPORTER_ODROID_H4_ULTRA__MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra app matej)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra app homelab-viewer)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra app homelab-test)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra app prometheus)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra apache status)"
    printf 'NODEEXPORTER_ODROID_H4_ULTRA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-odroid-h4-ultra apache prometheus)"

    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g app matej)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g app homelab-viewer)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g app homelab-test)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g app prometheus)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g apache status)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_2G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-2g apache prometheus)"

    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__MATEJ_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g app matej)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g app homelab-viewer)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g app homelab-test)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g app prometheus)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROXY_STATUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g apache status)"
    printf 'NODEEXPORTER_RASPBERRY_PI_4B_4G__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password nodeexporter-raspberry-pi-4b-4g apache prometheus)"

    printf 'NTFY__MATEJ_PASSWORD=%s\n' "$(load_password ntfy app matej)"
    printf 'NTFY__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password ntfy app homelab-test)"
    printf 'NTFY__HOMELAB_PUBLISHER_PASSWORD=%s\n' "$(load_password ntfy app homelab-publisher)"
    printf 'NTFY__HOMELAB_PUBLISHER_TOKEN=%s\n' "$(load_password ntfy app homelab-publisher-token)"
    printf 'NTFY__PROXY_STATUS_PASSWORD=%s\n' "$(load_password ntfy apache status)"
    printf 'NTFY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ntfy apache prometheus)"

    printf 'NETALERTX__ADMIN_PASSWORD=%s\n' "$(load_password netalertx app admin)"
    printf 'NETALERTX__PROMETHEUS_PASSWORD=%s\n' "$(load_password netalertx app prometheus)"
    printf 'NETALERTX__PROXY_STATUS_PASSWORD=%s\n' "$(load_password ntfy apache status)"
    printf 'NETALERTX__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ntfy apache prometheus)"

    printf 'OLLAMA__MATEJ_PASSWORD=%s\n' "$(load_password ollama app matej)"
    printf 'OLLAMA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password ollama app homelab-viewer)"
    printf 'OLLAMA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password ollama app homelab-test)"
    printf 'OLLAMA__OPENWEBUI_PASSWORD=%s\n' "$(load_password ollama app openwebui)"
    printf 'OLLAMA__PROXY_STATUS_PASSWORD=%s\n' "$(load_password ollama apache status)"
    printf 'OLLAMA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ollama apache prometheus)"

    printf 'OLLAMA_PRIVATE__MATEJ_PASSWORD=%s\n' "$(load_password ollama-private app matej)"
    printf 'OLLAMA_PRIVATE__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password ollama-private app homelab-viewer)"
    printf 'OLLAMA_PRIVATE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password ollama-private app homelab-test)"
    printf 'OLLAMA_PRIVATE__OPENWEBUI_PASSWORD=%s\n' "$(load_password ollama-private app openwebui)"
    printf 'OLLAMA_PRIVATE__PROXY_STATUS_PASSWORD=%s\n' "$(load_password ollama-private apache status)"
    printf 'OLLAMA_PRIVATE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ollama-private apache prometheus)"

    printf 'OMADACONTROLLER__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password omadacontroller app homelab-viewer)"
    printf 'OMADACONTROLLER__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password omadacontroller app homelab-test)"
    printf 'OMADACONTROLLER__PROXY_STATUS_PASSWORD=%s\n' "$(load_password omadacontroller apache status)"
    printf 'OMADACONTROLLER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password omadacontroller apache prometheus)"

    printf 'OPENWEBUI__MATEJ_PASSWORD=%s\n' "$(load_password openwebui app matej)"
    printf 'OPENWEBUI__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password openwebui app homelab-test)"
    printf 'OPENWEBUI__PROXY_STATUS_PASSWORD=%s\n' "$(load_password openwebui apache status)"
    printf 'OPENWEBUI__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password openwebui apache prometheus)"

    printf 'OPENWEBUI_PRIVATE__MATEJ_PASSWORD=%s\n' "$(load_password openwebui-private app matej)"
    printf 'OPENWEBUI_PRIVATE__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password openwebui-private app homelab-test)"
    printf 'OPENWEBUI_PRIVATE__PROXY_STATUS_PASSWORD=%s\n' "$(load_password openwebui-private apache status)"
    printf 'OPENWEBUI_PRIVATE__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password openwebui-private apache prometheus)"

    printf 'OPENSPEEDTEST__PROXY_STATUS_PASSWORD=%s\n' "$(load_password openspeedtest apache status)"
    printf 'OPENSPEEDTEST__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password openspeedtest apache prometheus)"

    printf 'OWNTRACKS__ADMIN_PASSWORD=%s\n' "$(load_password owntracks app admin)"
    printf 'OWNTRACKS__PROXY_STATUS_PASSWORD=%s\n' "$(load_password owntracks apache status)"
    printf 'OWNTRACKS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password owntracks apache prometheus)"

    printf 'PIHOLE_1_PRIMARY__PASSWORD=%s\n' "$(load_password pihole-1-primary app admin)"
    printf 'PIHOLE_1_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-primary app prometheus)"
    printf 'PIHOLE_1_PRIMARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-primary apache status)"
    printf 'PIHOLE_1_PRIMARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-primary apache prometheus)"

    printf 'PIHOLE_1_SECONDARY__PASSWORD=%s\n' "$(load_password pihole-1-secondary app admin)"
    printf 'PIHOLE_1_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary app prometheus)"
    printf 'PIHOLE_1_SECONDARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary apache status)"
    printf 'PIHOLE_1_SECONDARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary apache prometheus)"

    printf 'PIHOLE_2_PRIMARY__PASSWORD=%s\n' "$(load_password pihole-2-primary app admin)"
    printf 'PIHOLE_2_PRIMARY__PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-primary app prometheus)"
    printf 'PIHOLE_2_PRIMARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-primary apache status)"
    printf 'PIHOLE_2_PRIMARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-primary apache prometheus)"

    printf 'PIHOLE_2_SECONDARY__PASSWORD=%s\n' "$(load_password pihole-2-secondary app admin)"
    printf 'PIHOLE_2_SECONDARY__PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary app prometheus)"
    printf 'PIHOLE_2_SECONDARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary apache status)"
    printf 'PIHOLE_2_SECONDARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary apache prometheus)"

    printf 'PROMETHEUS__MATEJ_PASSWORD=%s\n' "$(load_password prometheus app matej)"
    printf 'PROMETHEUS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password prometheus app homelab-viewer)"
    printf 'PROMETHEUS__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password prometheus app homelab-test)"
    printf 'PROMETHEUS__PROMETHEUS_PASSWORD=%s\n' "$(load_password prometheus app prometheus)"
    printf 'PROMETHEUS__PROXY_STATUS_PASSWORD=%s\n' "$(load_password prometheus apache status)"
    printf 'PROMETHEUS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password prometheus apache prometheus)"

    printf 'RENOVATEBOT__MATEJ_PASSWORD=%s\n' "$(load_password renovatebot app matej)"
    printf 'RENOVATEBOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password renovatebot app homelab-viewer)"
    printf 'RENOVATEBOT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password renovatebot app homelab-test)"
    printf 'RENOVATEBOT__PROXY_STATUS_PASSWORD=%s\n' "$(load_password renovatebot apache status)"
    printf 'RENOVATEBOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password renovatebot apache prometheus)"

    printf 'SMTP4DEV__MATEJ_PASSWORD=%s\n' "$(load_password smtp4dev app matej)"
    printf 'SMTP4DEV__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password smtp4dev app homelab-viewer)"
    printf 'SMTP4DEV__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password smtp4dev app homelab-test)"
    printf 'SMTP4DEV__PROXY_STATUS_PASSWORD=%s\n' "$(load_password smtp4dev apache status)"
    printf 'SMTP4DEV__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password smtp4dev apache prometheus)"

    printf 'SPEEDTESTTRACKER__MATEJ_PASSWORD=%s\n' "$(load_password speedtesttracker app matej)"
    printf 'SPEEDTESTTRACKER__PROXY_STATUS_PASSWORD=%s\n' "$(load_password speedtesttracker apache status)"
    printf 'SPEEDTESTTRACKER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password speedtesttracker apache prometheus)"

    printf 'TVHEADEND__MATEJ_PASSWORD=%s\n' "$(load_password tvheadend app matej)"
    printf 'TVHEADEND__HOMELAB_STREAM_PASSWORD=%s\n' "$(load_password tvheadend app homelab-stream)"
    printf 'TVHEADEND__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password tvheadend app homelab-test)"
    printf 'TVHEADEND__PROXY_STATUS_PASSWORD=%s\n' "$(load_password tvheadend apache status)"
    printf 'TVHEADEND__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password tvheadend apache prometheus)"

    printf 'UNBOUND_1_DEFAULT__MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-default app matej)"
    printf 'UNBOUND_1_DEFAULT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-default app homelab-viewer)"
    printf 'UNBOUND_1_DEFAULT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-default app homelab-test)"
    printf 'UNBOUND_1_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-default app prometheus)"
    printf 'UNBOUND_1_DEFAULT__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-default apache status)"
    printf 'UNBOUND_1_DEFAULT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-default apache prometheus)"

    printf 'UNBOUND_1_GUESTS__MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-guests app matej)"
    printf 'UNBOUND_1_GUESTS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-guests app homelab-viewer)"
    printf 'UNBOUND_1_GUESTS__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-guests app homelab-test)"
    printf 'UNBOUND_1_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-guests app prometheus)"
    printf 'UNBOUND_1_GUESTS__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-guests apache status)"
    printf 'UNBOUND_1_GUESTS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-guests apache prometheus)"

    printf 'UNBOUND_1_IOT__MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-iot app matej)"
    printf 'UNBOUND_1_IOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-iot app homelab-viewer)"
    printf 'UNBOUND_1_IOT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-iot app homelab-test)"
    printf 'UNBOUND_1_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-iot app prometheus)"
    printf 'UNBOUND_1_IOT__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-iot apache status)"
    printf 'UNBOUND_1_IOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-iot apache prometheus)"

    printf 'UNBOUND_1_MATEJ__MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-matej app matej)"
    printf 'UNBOUND_1_MATEJ__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-matej app homelab-viewer)"
    printf 'UNBOUND_1_MATEJ__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-matej app homelab-test)"
    printf 'UNBOUND_1_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-matej app prometheus)"
    printf 'UNBOUND_1_MATEJ__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-matej apache status)"
    printf 'UNBOUND_1_MATEJ__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-matej apache prometheus)"

    printf 'UNBOUND_1_MONIKA__MATEJ_PASSWORD=%s\n' "$(load_password unbound-1-monika app matej)"
    printf 'UNBOUND_1_MONIKA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-1-monika app homelab-viewer)"
    printf 'UNBOUND_1_MONIKA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-1-monika app homelab-test)"
    printf 'UNBOUND_1_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-monika app prometheus)"
    printf 'UNBOUND_1_MONIKA__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-monika apache status)"
    printf 'UNBOUND_1_MONIKA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-monika apache prometheus)"

    printf 'UNBOUND_2_DEFAULT__MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-default app matej)"
    printf 'UNBOUND_2_DEFAULT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-default app homelab-viewer)"
    printf 'UNBOUND_2_DEFAULT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-default app homelab-test)"
    printf 'UNBOUND_2_DEFAULT__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-default app prometheus)"
    printf 'UNBOUND_2_DEFAULT__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-default apache status)"
    printf 'UNBOUND_2_DEFAULT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-default apache prometheus)"

    printf 'UNBOUND_2_GUESTS__MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-guests app matej)"
    printf 'UNBOUND_2_GUESTS__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-guests app homelab-viewer)"
    printf 'UNBOUND_2_GUESTS__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-guests app homelab-test)"
    printf 'UNBOUND_2_GUESTS__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-guests app prometheus)"
    printf 'UNBOUND_2_GUESTS__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-guests apache status)"
    printf 'UNBOUND_2_GUESTS__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-guests apache prometheus)"

    printf 'UNBOUND_2_IOT__MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-iot app matej)"
    printf 'UNBOUND_2_IOT__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-iot app homelab-viewer)"
    printf 'UNBOUND_2_IOT__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-iot app homelab-test)"
    printf 'UNBOUND_2_IOT__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-iot app prometheus)"
    printf 'UNBOUND_2_IOT__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-iot apache status)"
    printf 'UNBOUND_2_IOT__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-iot apache prometheus)"

    printf 'UNBOUND_2_MATEJ__MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-matej app matej)"
    printf 'UNBOUND_2_MATEJ__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-matej app homelab-viewer)"
    printf 'UNBOUND_2_MATEJ__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-matej app homelab-test)"
    printf 'UNBOUND_2_MATEJ__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-matej app prometheus)"
    printf 'UNBOUND_2_MATEJ__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-matej apache status)"
    printf 'UNBOUND_2_MATEJ__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-matej apache prometheus)"

    printf 'UNBOUND_2_MONIKA__MATEJ_PASSWORD=%s\n' "$(load_password unbound-2-monika app matej)"
    printf 'UNBOUND_2_MONIKA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unbound-2-monika app homelab-viewer)"
    printf 'UNBOUND_2_MONIKA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unbound-2-monika app homelab-test)"
    printf 'UNBOUND_2_MONIKA__PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-monika app prometheus)"
    printf 'UNBOUND_2_MONIKA__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-monika apache status)"
    printf 'UNBOUND_2_MONIKA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-monika apache prometheus)"

    printf 'UNIFICONTROLLER__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password unificontroller app homelab-viewer)"
    printf 'UNIFICONTROLLER__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password unificontroller app homelab-test)"
    printf 'UNIFICONTROLLER__PROXY_STATUS_PASSWORD=%s\n' "$(load_password unificontroller apache status)"
    printf 'UNIFICONTROLLER__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unificontroller apache prometheus)"

    printf 'UPTIMEKUMA_1__MATEJ_PASSWORD=%s\n' "$(load_password uptimekuma-1 app matej)"
    printf 'UPTIMEKUMA_1__PROXY_STATUS_PASSWORD=%s\n' "$(load_password uptimekuma-1 apache status)"
    printf 'UPTIMEKUMA_1__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password uptimekuma-1 apache prometheus)"

    printf 'UPTIMEKUMA_2__MATEJ_PASSWORD=%s\n' "$(load_password uptimekuma-2 app matej)"
    printf 'UPTIMEKUMA_2__PROXY_STATUS_PASSWORD=%s\n' "$(load_password uptimekuma-2 apache status)"
    printf 'UPTIMEKUMA_2__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password uptimekuma-2 apache prometheus)"

    printf 'VAULTWARDEN__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password vaultwarden app homelab-test)"
    printf 'VAULTWARDEN__PROXY_STATUS_PASSWORD=%s\n' "$(load_password vaultwarden apache status)"
    printf 'VAULTWARDEN__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password vaultwarden apache prometheus)"

    printf 'VIKUNJA__MATEJ_PASSWORD=%s\n' "$(load_password vikunja app matej)"
    printf 'VIKUNJA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password vikunja app homelab-test)"
    printf 'VIKUNJA__PROXY_STATUS_PASSWORD=%s\n' "$(load_password vikunja apache status)"
    printf 'VIKUNJA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password vikunja apache prometheus)"

    printf 'WIKIPEDIA__MATEJ_PASSWORD=%s\n' "$(load_password kiwix-wikipedia app matej)"
    printf 'WIKIPEDIA__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password kiwix-wikipedia app homelab-viewer)"
    printf 'WIKIPEDIA__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password kiwix-wikipedia app homelab-test)"
    printf 'WIKIPEDIA__PROXY_STATUS_PASSWORD=%s\n' "$(load_password kiwix-wikipedia apache status)"
    printf 'WIKIPEDIA__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password kiwix-wikipedia apache prometheus)"

    printf 'WIKTIONARY__MATEJ_PASSWORD=%s\n' "$(load_password kiwix-wiktionary app matej)"
    printf 'WIKTIONARY__HOMELAB_VIEWER_PASSWORD=%s\n' "$(load_password kiwix-wiktionary app homelab-viewer)"
    printf 'WIKTIONARY__HOMELAB_TEST_PASSWORD=%s\n' "$(load_password kiwix-wiktionary app homelab-test)"
    printf 'WIKTIONARY__PROXY_STATUS_PASSWORD=%s\n' "$(load_password kiwix-wiktionary apache status)"
    printf 'WIKTIONARY__PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password kiwix-wiktionary apache prometheus)"
} >>'.secrets.env'

chmod 0400 '.secrets.env'
