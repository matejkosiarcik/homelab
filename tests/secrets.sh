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

    printf 'CERTBOT_ADMIN_PASSWORD=%s\n' "$(load_password certbot apache admin)"
    printf 'CERTBOT_VIEWER_PASSWORD=%s\n' "$(load_password certbot apache viewer)"
    printf 'CERTBOT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password certbot apache status)"
    printf 'CERTBOT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password certbot apache prometheus)"

    printf 'CHANGEDETECTION_ADMIN_PASSWORD=%s\n' "$(load_password changedetection app admin)"
    printf 'CHANGEDETECTION_PROXY_STATUS_PASSWORD=%s\n' "$(load_password changedetection apache status)"
    printf 'CHANGEDETECTION_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password changedetection apache prometheus)"

    printf 'DAWARICH_MATEJ_PASSWORD=%s\n' "$(load_password dawarich app matej)"
    printf 'DAWARICH_TEST_PASSWORD=%s\n' "$(load_password dawarich app test)"
    printf 'DAWARICH_PROXY_STATUS_PASSWORD=%s\n' "$(load_password dawarich apache status)"
    printf 'DAWARICH_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password dawarich apache prometheus)"
    printf 'DAWARICH_PROMETHEUS_PASSWORD=%s\n' "$(load_password dawarich app prometheus)"

    printf 'DOCKER_CACHE_PROXY_DOCKERHUB_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-cache-proxy-dockerhub apache status)"
    printf 'DOCKER_CACHE_PROXY_DOCKERHUB_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-cache-proxy-dockerhub apache prometheus)"

    # printf 'DOCKER_STATS_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-macbook-pro-2012 app prometheus)"
    # printf 'DOCKER_STATS_MACBOOK_PRO_2012_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-macbook-pro-2012 apache status)"
    # printf 'DOCKER_STATS_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-macbook-pro-2012 apache prometheus)"

    printf 'DOCKER_STATS_ODROID_H3_ADMIN_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app admin)"
    printf 'DOCKER_STATS_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 app prometheus)"
    printf 'DOCKER_STATS_ODROID_H3_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 apache status)"
    printf 'DOCKER_STATS_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h3 apache prometheus)"

    printf 'DOCKER_STATS_ODROID_H4_ULTRA_ADMIN_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app admin)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra app prometheus)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra apache status)"
    printf 'DOCKER_STATS_ODROID_H4_ULTRA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-odroid-h4-ultra apache prometheus)"

    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_ADMIN_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b app admin)"
    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b app prometheus)"
    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b apache status)"
    # printf 'DOCKER_STATS_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-3b apache prometheus)"

    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_ADMIN_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app admin)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g app prometheus)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g apache status)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-2g apache prometheus)"

    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_ADMIN_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app admin)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g app prometheus)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g apache status)"
    printf 'DOCKER_STATS_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password docker-stats-raspberry-pi-4b-4g apache prometheus)"

    printf 'DOZZLE_ADMIN_PASSWORD=%s\n' "$(load_password dozzle app admin)"
    printf 'DOZZLE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password dozzle apache status)"
    printf 'DOZZLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password dozzle apache prometheus)"

    printf 'GATUS_1_ADMIN_PASSWORD=%s\n' "$(load_password gatus-1 app admin)"
    printf 'GATUS_1_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-1 app prometheus)"
    printf 'GATUS_1_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-1 apache status)"
    printf 'GATUS_1_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-1 apache prometheus)"

    printf 'GATUS_2_ADMIN_PASSWORD=%s\n' "$(load_password gatus-2 app admin)"
    printf 'GATUS_2_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 app prometheus)"
    printf 'GATUS_2_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-2 apache status)"
    printf 'GATUS_2_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 apache prometheus)"

    printf 'GLANCES_MACBOOK_PRO_2012_PASSWORD=%s\n' "$(load_password glances-macbook-pro-2012 app admin)"
    printf 'GLANCES_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-macbook-pro-2012 app prometheus)"
    printf 'GLANCES_MACBOOK_PRO_2012_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances-macbook-pro-2012 apache status)"
    printf 'GLANCES_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-macbook-pro-2012 apache prometheus)"

    printf 'GLANCES_ODROID_H3_PASSWORD=%s\n' "$(load_password glances-odroid-h3 app admin)"
    printf 'GLANCES_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-odroid-h3 app prometheus)"
    printf 'GLANCES_ODROID_H3_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances-odroid-h3 apache status)"
    printf 'GLANCES_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-odroid-h3 apache prometheus)"

    printf 'GLANCES_ODROID_H4_ULTRA_PASSWORD=%s\n' "$(load_password glances-odroid-h4-ultra app admin)"
    printf 'GLANCES_ODROID_H4_ULTRA_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-odroid-h4-ultra app prometheus)"
    printf 'GLANCES_ODROID_H4_ULTRA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances-odroid-h4-ultra apache status)"
    printf 'GLANCES_ODROID_H4_ULTRA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-odroid-h4-ultra apache prometheus)"

    printf 'GLANCES_RASPBERRY_PI_3B_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-3b app admin)"
    printf 'GLANCES_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-3b app prometheus)"
    printf 'GLANCES_RASPBERRY_PI_3B_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-3b apache status)"
    printf 'GLANCES_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-3b apache prometheus)"

    printf 'GLANCES_RASPBERRY_PI_4B_2G_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-4b-2g app admin)"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-4b-2g app prometheus)"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-4b-2g apache status)"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-4b-2g apache prometheus)"

    printf 'GLANCES_RASPBERRY_PI_4B_4G_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-4b-4g app admin)"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-4b-4g app prometheus)"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-4b-4g apache status)"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances-raspberry-pi-4b-4g apache prometheus)"

    printf 'GOTIFY_ADMIN_PASSWORD=%s\n' "$(load_password gotify app admin)"
    printf 'GOTIFY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gotify apache status)"
    printf 'GOTIFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gotify apache prometheus)"

    printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$(load_password grafana app admin)"
    printf 'GRAFANA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password grafana apache status)"
    printf 'GRAFANA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password grafana apache prometheus)"

    printf 'GROCERIES_TEST_PASSWORD=%s\n' "$(load_password groceries app test)"
    printf 'GROCERIES_PROXY_STATUS_PASSWORD=%s\n' "$(load_password groceries apache status)"
    printf 'GROCERIES_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password groceries apache prometheus)"

    printf 'HEALTHCHECKS_MATEJ_PASSWORD=%s\n' "$(load_password healthchecks app matej)"
    printf 'HEALTHCHECKS_TEST_PASSWORD=%s\n' "$(load_password healthchecks app test)"
    printf 'HEALTHCHECKS_API_KEY_READONLY=%s\n' "$(load_password healthchecks app api-key-readonly)"
    printf 'HEALTHCHECKS_API_KEY_READWRITE=%s\n' "$(load_password healthchecks app api-key-readwrite)"
    printf 'HEALTHCHECKS_PING_KEY=%s\n' "$(load_password healthchecks app ping-key)"
    printf 'HEALTHCHECKS_PROMETHEUS_PROJECT=%s\n' "$(load_password healthchecks app project-id)"
    printf 'HEALTHCHECKS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password healthchecks apache status)"
    printf 'HEALTHCHECKS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password healthchecks apache prometheus)"

    printf 'HOME_ASSISTANT_TEST_PASSWORD=%s\n' "$(load_password home-assistant app test)"
    printf 'HOME_ASSISTANT_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password home-assistant app api-key)"
    printf 'HOME_ASSISTANT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password home-assistant apache status)"
    printf 'HOME_ASSISTANT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password home-assistant apache prometheus)"

    printf 'HOMEPAGE_ADMIN_PASSWORD=%s\n' "$(load_password homepage app admin)"
    printf 'HOMEPAGE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password homepage apache status)"
    printf 'HOMEPAGE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password homepage apache prometheus)"

    printf 'JELLYFIN_TEST_PASSWORD=%s\n' "$(load_password jellyfin app test)"
    printf 'JELLYFIN_PROMETHEUS_PASSWORD=%s\n' "$(load_password jellyfin app prometheus)"
    printf 'JELLYFIN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password jellyfin apache status)"
    printf 'JELLYFIN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password jellyfin apache prometheus)"

    printf 'MINIO_ADMIN_PASSWORD=%s\n' "$(load_password minio app admin)"
    printf 'MINIO_USER_PASSWORD=%s\n' "$(load_password minio app user)"
    printf 'MINIO_TEST_PASSWORD=%s\n' "$(load_password minio app test)"
    printf 'MINIO_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password minio app prometheus-token)"
    printf 'MINIO_PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio apache status)"
    printf 'MINIO_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password minio apache prometheus)"
    printf 'MINIO_CONSOLE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio apache status)"
    printf 'MINIO_CONSOLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password minio apache prometheus)"

    printf 'MOTIONEYE_KITCHEN_MATEJ_PASSWORD=%s\n' "$(load_password motioneye-kitchen app matej)"
    printf 'MOTIONEYE_KITCHEN_STREAM_PASSWORD=%s\n' "$(load_password motioneye-kitchen app stream)"
    printf 'MOTIONEYE_KITCHEN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password motioneye-kitchen apache status)"
    printf 'MOTIONEYE_KITCHEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password motioneye-kitchen apache prometheus)"

    printf 'NODE_EXPORTER_MACBOOK_PRO_2012_ADMIN_PASSWORD=%s\n' "$(load_password node-exporter-macbook-pro-2012 app admin)"
    printf 'NODE_EXPORTER_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-macbook-pro-2012 app prometheus)"
    printf 'NODE_EXPORTER_MACBOOK_PRO_2012_PROXY_STATUS_PASSWORD=%s\n' "$(load_password node-exporter-macbook-pro-2012 apache status)"
    printf 'NODE_EXPORTER_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-macbook-pro-2012 apache prometheus)"

    printf 'NODE_EXPORTER_ODROID_H3_ADMIN_PASSWORD=%s\n' "$(load_password node-exporter-odroid-h3 app admin)"
    printf 'NODE_EXPORTER_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-odroid-h3 app prometheus)"
    printf 'NODE_EXPORTER_ODROID_H3_PROXY_STATUS_PASSWORD=%s\n' "$(load_password node-exporter-odroid-h3 apache status)"
    printf 'NODE_EXPORTER_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-odroid-h3 apache prometheus)"

    printf 'NODE_EXPORTER_ODROID_H4_ULTRA_ADMIN_PASSWORD=%s\n' "$(load_password node-exporter-odroid-h4-ultra app admin)"
    printf 'NODE_EXPORTER_ODROID_H4_ULTRA_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-odroid-h4-ultra app prometheus)"
    printf 'NODE_EXPORTER_ODROID_H4_ULTRA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password node-exporter-odroid-h4-ultra apache status)"
    printf 'NODE_EXPORTER_ODROID_H4_ULTRA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-odroid-h4-ultra apache prometheus)"

    printf 'NODE_EXPORTER_RASPBERRY_PI_3B_ADMIN_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-3b app admin)"
    printf 'NODE_EXPORTER_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-3b app prometheus)"
    printf 'NODE_EXPORTER_RASPBERRY_PI_3B_PROXY_STATUS_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-3b apache status)"
    printf 'NODE_EXPORTER_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-3b apache prometheus)"

    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_2G_ADMIN_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-4b-2g app admin)"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-4b-2g app prometheus)"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_2G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-4b-2g apache status)"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-4b-2g apache prometheus)"

    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_4G_ADMIN_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-4b-4g app admin)"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-4b-4g app prometheus)"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_4G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-4b-4g apache status)"
    printf 'NODE_EXPORTER_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password node-exporter-raspberry-pi-4b-4g apache prometheus)"

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

    printf 'OLLAMA_ADMIN_PASSWORD=%s\n' "$(load_password ollama app admin)"
    printf 'OLLAMA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password ollama apache status)"
    printf 'OLLAMA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ollama apache prometheus)"

    printf 'OLLAMA_PRIVATE_ADMIN_PASSWORD=%s\n' "$(load_password ollama-private app admin)"
    printf 'OLLAMA_PRIVATE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password ollama-private apache status)"
    printf 'OLLAMA_PRIVATE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ollama-private apache prometheus)"

    printf 'OMADA_CONTROLLER_READONLY_PASSWORD=%s\n' "$(load_password omada-controller app readonly)"
    printf 'OMADA_CONTROLLER_TEST_PASSWORD=%s\n' "$(load_password omada-controller app test)"
    printf 'OMADA_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password omada-controller apache status)"
    printf 'OMADA_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password omada-controller apache prometheus)"

    printf 'OPENWEBUI_ADMIN_PASSWORD=%s\n' "$(load_password openwebui app admin)"
    printf 'OPENWEBUI_PROXY_STATUS_PASSWORD=%s\n' "$(load_password openwebui apache status)"
    printf 'OPENWEBUI_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password openwebui apache prometheus)"

    printf 'OPENWEBUI_PRIVATE_ADMIN_PASSWORD=%s\n' "$(load_password openwebui-private app admin)"
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

    printf 'PROMETHEUS_ADMIN_PASSWORD=%s\n' "$(load_password prometheus app admin)"
    printf 'PROMETHEUS_PROMETHEUS_PASSWORD=%s\n' "$(load_password prometheus app prometheus)"
    printf 'PROMETHEUS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password prometheus apache status)"
    printf 'PROMETHEUS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password prometheus apache prometheus)"

    printf 'SMTP4DEV_ADMIN_PASSWORD=%s\n' "$(load_password smtp4dev app admin)"
    printf 'SMTP4DEV_PROXY_STATUS_PASSWORD=%s\n' "$(load_password smtp4dev apache status)"
    printf 'SMTP4DEV_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password smtp4dev apache prometheus)"

    printf 'SPEEDTEST_TRACKER_ADMIN_PASSWORD=%s\n' "$(load_password speedtest-tracker app admin)"
    printf 'SPEEDTEST_TRACKER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password speedtest-tracker apache status)"
    printf 'SPEEDTEST_TRACKER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password speedtest-tracker apache prometheus)"

    printf 'TVHEADEND_STREAM_PASSWORD=%s\n' "$(load_password tvheadend app stream)"
    printf 'TVHEADEND_TEST_PASSWORD=%s\n' "$(load_password tvheadend app test)"
    printf 'TVHEADEND_PROXY_STATUS_PASSWORD=%s\n' "$(load_password tvheadend apache status)"
    printf 'TVHEADEND_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password tvheadend apache prometheus)"

    printf 'UNBOUND_1_DEFAULT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-default app prometheus)"
    printf 'UNBOUND_1_DEFAULT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-default apache status)"
    printf 'UNBOUND_1_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-default apache prometheus)"

    printf 'UNBOUND_1_MATEJ_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-matej app prometheus)"
    printf 'UNBOUND_1_MATEJ_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-matej apache status)"
    printf 'UNBOUND_1_MATEJ_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-matej apache prometheus)"

    printf 'UNBOUND_1_MONIKA_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-monika app prometheus)"
    printf 'UNBOUND_1_MONIKA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-monika apache status)"
    printf 'UNBOUND_1_MONIKA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-monika apache prometheus)"

    printf 'UNBOUND_1_IOT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-iot app prometheus)"
    printf 'UNBOUND_1_IOT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-iot apache status)"
    printf 'UNBOUND_1_IOT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-iot apache prometheus)"

    printf 'UNBOUND_1_GUESTS_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-guests app prometheus)"
    printf 'UNBOUND_1_GUESTS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-guests apache status)"
    printf 'UNBOUND_1_GUESTS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-guests apache prometheus)"

    printf 'UNBOUND_2_DEFAULT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-default app prometheus)"
    printf 'UNBOUND_2_DEFAULT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-default apache status)"
    printf 'UNBOUND_2_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-default apache prometheus)"

    printf 'UNBOUND_2_MATEJ_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-matej app prometheus)"
    printf 'UNBOUND_2_MATEJ_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-matej apache status)"
    printf 'UNBOUND_2_MATEJ_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-matej apache prometheus)"

    printf 'UNBOUND_2_MONIKA_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-monika app prometheus)"
    printf 'UNBOUND_2_MONIKA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-monika apache status)"
    printf 'UNBOUND_2_MONIKA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-monika apache prometheus)"

    printf 'UNBOUND_2_IOT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-iot app prometheus)"
    printf 'UNBOUND_2_IOT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-iot apache status)"
    printf 'UNBOUND_2_IOT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-iot apache prometheus)"

    printf 'UNBOUND_2_GUESTS_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-guests app prometheus)"
    printf 'UNBOUND_2_GUESTS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-guests apache status)"
    printf 'UNBOUND_2_GUESTS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-guests apache prometheus)"

    printf 'UNIFI_CONTROLLER_READONLY_PASSWORD=%s\n' "$(load_password unifi-controller app readonly)"
    printf 'UNIFI_CONTROLLER_TEST_PASSWORD=%s\n' "$(load_password unifi-controller app test)"
    printf 'UNIFI_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unifi-controller apache status)"
    printf 'UNIFI_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unifi-controller apache prometheus)"

    printf 'UPTIME_KUMA_MATEJ_PASSWORD=%s\n' "$(load_password uptime-kuma app matej)"
    printf 'UPTIME_KUMA_PROMETHEUS_PASSWORD=%s\n' "$(load_password uptime-kuma app prometheus)"
    printf 'UPTIME_KUMA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password uptime-kuma apache status)"
    printf 'UPTIME_KUMA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password uptime-kuma apache prometheus)"

    printf 'VAULTWARDEN_TEST_PASSWORD=%s\n' "$(load_password vaultwarden app test)"
    printf 'VAULTWARDEN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password vaultwarden apache status)"
    printf 'VAULTWARDEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password vaultwarden apache prometheus)"

    printf 'VIKUNJA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password vikunja apache status)"
    printf 'VIKUNJA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password vikunja apache prometheus)"

    printf 'WIKIPEDIA_ADMIN_PASSWORD=%s\n' "$(load_password kiwix-wikipedia app admin)"
    printf 'WIKIPEDIA_PROXY_STATUS_PASSWORD=%s\n' "$(load_password kiwix-wikipedia apache status)"
    printf 'WIKIPEDIA_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password kiwix-wikipedia apache prometheus)"

    printf 'WIKTIONARY_ADMIN_PASSWORD=%s\n' "$(load_password kiwix-wiktionary app admin)"
    printf 'WIKTIONARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password kiwix-wiktionary apache status)"
    printf 'WIKTIONARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password kiwix-wiktionary apache prometheus)"
} >>'.secrets.env'

chmod 0400 '.secrets.env'
