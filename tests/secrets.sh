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
    printf 'ACTUALBUDGET_SYNC_ID=%s\n' "$(load_password actualbudget app sync-id)"
    printf 'ACTUALBUDGET_PROXY_STATUS_PASSWORD=%s\n' "$(load_password actualbudget http-proxy status)"
    printf 'ACTUALBUDGET_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password actualbudget http-proxy prometheus)"

    printf 'ACTUALBUDGET_PUBLIC_PASSWORD=%s\n' "$(load_password actualbudget-public app admin)"
    printf 'ACTUALBUDGET_PUBLIC_SYNC_ID=%s\n' "$(load_password actualbudget-public app sync-id)"
    printf 'ACTUALBUDGET_PUBLIC_PROXY_STATUS_PASSWORD=%s\n' "$(load_password actualbudget-public http-proxy status)"
    printf 'ACTUALBUDGET_PUBLIC_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password actualbudget-public http-proxy prometheus)"

    printf 'CHANGEDETECTION_PASSWORD=%s\n' "$(load_password changedetection app admin)"
    printf 'CHANGEDETECTION_PROXY_STATUS_PASSWORD=%s\n' "$(load_password changedetection http-proxy status)"
    printf 'CHANGEDETECTION_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password changedetection http-proxy prometheus)"

    printf 'DOCKERHUB_CACHE_PROXY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password dockerhub-cache-proxy http-proxy status)"
    printf 'DOCKERHUB_CACHE_PROXY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password dockerhub-cache-proxy http-proxy prometheus)"

    printf 'DOZZLE_ADMIN_PASSWORD=%s\n' "$(load_password dozzle app admin)"
    printf 'DOZZLE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password dozzle http-proxy status)"
    printf 'DOZZLE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password dozzle http-proxy prometheus)"

    printf 'GATUS_1_ADMIN_PASSWORD=%s\n' "$(load_password gatus-1 app admin)"
    printf 'GATUS_1_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-1 app prometheus)"
    printf 'GATUS_1_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-1 http-proxy status)"
    printf 'GATUS_1_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-1 http-proxy prometheus)"

    printf 'GATUS_2_ADMIN_PASSWORD=%s\n' "$(load_password gatus-2 app admin)"
    printf 'GATUS_2_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 app prometheus)"
    printf 'GATUS_2_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-2 http-proxy status)"
    printf 'GATUS_2_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 http-proxy prometheus)"

    printf 'GLANCES_MACBOOK_PRO_2012_PASSWORD=%s\n' "$(load_password glances--macbook-pro-2012 app admin)"
    printf 'GLANCES_MACBOOK_PRO_2012_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--macbook-pro-2012 app prometheus)"
    printf 'GLANCES_MACBOOK_PRO_2012_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances--macbook-pro-2012 http-proxy status)"
    printf 'GLANCES_MACBOOK_PRO_2012_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--macbook-pro-2012 http-proxy prometheus)"

    printf 'GLANCES_ODROID_H3_PASSWORD=%s\n' "$(load_password glances--odroid-h3 app admin)"
    printf 'GLANCES_ODROID_H3_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--odroid-h3 app prometheus)"
    printf 'GLANCES_ODROID_H3_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances--odroid-h3 http-proxy status)"
    printf 'GLANCES_ODROID_H3_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--odroid-h3 http-proxy prometheus)"

    printf 'GLANCES_RASPBERRY_PI_3B_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-3b app admin)"
    printf 'GLANCES_RASPBERRY_PI_3B_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-3b app prometheus)"
    printf 'GLANCES_RASPBERRY_PI_3B_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-3b http-proxy status)"
    printf 'GLANCES_RASPBERRY_PI_3B_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-3b http-proxy prometheus)"

    printf 'GLANCES_RASPBERRY_PI_4B_2G_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-4b-2g app admin)"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-4b-2g app prometheus)"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-4b-2g http-proxy status)"
    printf 'GLANCES_RASPBERRY_PI_4B_2G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-4b-2g http-proxy prometheus)"

    printf 'GLANCES_RASPBERRY_PI_4B_4G_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-4b-4g app admin)"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-4b-4g app prometheus)"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROXY_STATUS_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-4b-4g http-proxy status)"
    printf 'GLANCES_RASPBERRY_PI_4B_4G_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password glances--raspberry-pi-4b-4g http-proxy prometheus)"

    printf 'HEALTHCHECKS_ADMIN_PASSWORD=%s\n' "$(load_password healthchecks app admin)"
    printf 'HEALTHCHECKS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password healthchecks http-proxy status)"
    printf 'HEALTHCHECKS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password healthchecks http-proxy prometheus)"

    printf 'HOMEASSISTANT_ADMIN_PASSWORD=%s\n' "$(load_password homeassistant app admin)"
    printf 'HOMEASSISTANT_HOMEPAGE_PASSWORD=%s\n' "$(load_password homeassistant app homepage)"
    printf 'HOMEASSISTANT_MONIKA_PASSWORD=%s\n' "$(load_password homeassistant app monika)"
    printf 'HOMEASSISTANT_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password homeassistant app prometheus-api-key)"
    printf 'HOMEASSISTANT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password homeassistant http-proxy status)"
    printf 'HOMEASSISTANT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password homeassistant http-proxy prometheus)"

    printf 'HOMEPAGE_ADMIN_PASSWORD=%s\n' "$(load_password homepage app admin)"
    printf 'HOMEPAGE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password homepage http-proxy status)"
    printf 'HOMEPAGE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password homepage http-proxy prometheus)"

    printf 'JELLYFIN_ADMIN_PASSWORD=%s\n' "$(load_password jellyfin app admin)"
    printf 'JELLYFIN_MONIKA_PASSWORD=%s\n' "$(load_password jellyfin app monika)"
    printf 'JELLYFIN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password jellyfin http-proxy status)"
    printf 'JELLYFIN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password jellyfin http-proxy prometheus)"

    printf 'MINIO_ADMIN_PASSWORD=%s\n' "$(load_password minio app admin)"
    printf 'MINIO_USER_PASSWORD=%s\n' "$(load_password minio app user)"
    printf 'MINIO_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password minio app prometheus-token)"
    printf 'MINIO_PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio http-proxy status)"
    printf 'MINIO_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password minio http-proxy prometheus)"

    printf 'MOTIONEYE_STOVE_ADMIN_PASSWORD=%s\n' "$(load_password motioneye-stove app admin)"
    printf 'MOTIONEYE_STOVE_USER_PASSWORD=%s\n' "$(load_password motioneye-stove app user)"
    printf 'MOTIONEYE_STOVE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password motioneye-stove http-proxy status)"
    printf 'MOTIONEYE_STOVE_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password motioneye-stove http-proxy prometheus)"

    printf 'NTFY_ADMIN_PASSWORD=%s\n' "$(load_password ntfy app admin)"
    printf 'NTFY_USER_PASSWORD=%s\n' "$(load_password ntfy app user)"
    printf 'NTFY_PUBLISHER_PASSWORD=%s\n' "$(load_password ntfy app publisher)"
    printf 'NTFY_PUBLISHER_TOKEN=%s\n' "$(load_password ntfy app publisher-token)"
    printf 'NTFY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password ntfy http-proxy status)"
    printf 'NTFY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password ntfy http-proxy prometheus)"

    printf 'OMADA_CONTROLLER_ADMIN_PASSWORD=%s\n' "$(load_password omada-controller app admin)"
    printf 'OMADA_CONTROLLER_VIEWER_PASSWORD=%s\n' "$(load_password omada-controller app viewer)"
    printf 'OMADA_CONTROLLER_HOMEPAGE_PASSWORD=%s\n' "$(load_password omada-controller app homepage)"
    printf 'OMADA_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password omada-controller http-proxy status)"
    printf 'OMADA_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password omada-controller http-proxy prometheus)"

    printf 'OPENSPEEDTEST_PROXY_STATUS_PASSWORD=%s\n' "$(load_password openspeedtest http-proxy status)"
    printf 'OPENSPEEDTEST_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password openspeedtest http-proxy prometheus)"

    printf 'PIHOLE_1_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-1-primary app admin)"
    printf 'PIHOLE_1_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-primary app prometheus)"
    printf 'PIHOLE_1_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-primary http-proxy status)"
    printf 'PIHOLE_1_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-primary http-proxy prometheus)"

    printf 'PIHOLE_1_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-1-secondary app admin)"
    printf 'PIHOLE_1_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary app prometheus)"
    printf 'PIHOLE_1_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary http-proxy status)"
    printf 'PIHOLE_1_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary http-proxy prometheus)"

    printf 'PIHOLE_2_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-2-primary app admin)"
    printf 'PIHOLE_2_PRIMARY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-primary app prometheus)"
    printf 'PIHOLE_2_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-primary http-proxy status)"
    printf 'PIHOLE_2_PRIMARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-primary http-proxy prometheus)"

    printf 'PIHOLE_2_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-2-secondary app admin)"
    printf 'PIHOLE_2_SECONDARY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary app prometheus)"
    printf 'PIHOLE_2_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary http-proxy status)"
    printf 'PIHOLE_2_SECONDARY_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary http-proxy prometheus)"

    printf 'PROMETHEUS_ADMIN_PASSWORD=%s\n' "$(load_password prometheus app admin)"
    printf 'PROMETHEUS_PROMETHEUS_PASSWORD=%s\n' "$(load_password prometheus app prometheus)"
    printf 'PROMETHEUS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password prometheus http-proxy status)"
    printf 'PROMETHEUS_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password prometheus http-proxy prometheus)"

    printf 'SMTP4DEV_PROXY_STATUS_PASSWORD=%s\n' "$(load_password smtp4dev http-proxy status)"
    printf 'SMTP4DEV_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password smtp4dev http-proxy prometheus)"

    printf 'SPEEDTEST_TRACKER_ADMIN_PASSWORD=%s\n' "$(load_password speedtest-tracker app admin)"
    printf 'SPEEDTEST_TRACKER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password speedtest-tracker http-proxy status)"
    printf 'SPEEDTEST_TRACKER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password speedtest-tracker http-proxy prometheus)"

    printf 'TVHEADEND_ADMIN_PASSWORD=%s\n' "$(load_password tvheadend app admin)"
    printf 'TVHEADEND_USER_PASSWORD=%s\n' "$(load_password tvheadend app user)"
    printf 'TVHEADEND_PROXY_STATUS_PASSWORD=%s\n' "$(load_password tvheadend http-proxy status)"
    printf 'TVHEADEND_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password tvheadend http-proxy prometheus)"

    printf 'UNBOUND_1_DEFAULT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-default app prometheus)"
    printf 'UNBOUND_1_DEFAULT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-default http-proxy status)"
    printf 'UNBOUND_1_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-default http-proxy prometheus)"

    printf 'UNBOUND_1_OPEN_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-open app prometheus)"
    printf 'UNBOUND_1_OPEN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-1-open http-proxy status)"
    printf 'UNBOUND_1_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-1-open http-proxy prometheus)"

    printf 'UNBOUND_2_DEFAULT_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-default app prometheus)"
    printf 'UNBOUND_2_DEFAULT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-default http-proxy status)"
    printf 'UNBOUND_2_DEFAULT_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-default http-proxy prometheus)"

    printf 'UNBOUND_2_OPEN_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-open app prometheus)"
    printf 'UNBOUND_2_OPEN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unbound-2-open http-proxy status)"
    printf 'UNBOUND_2_OPEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unbound-2-open http-proxy prometheus)"

    printf 'UNIFI_CONTROLLER_ADMIN_PASSWORD=%s\n' "$(load_password unifi-controller app admin)"
    printf 'UNIFI_CONTROLLER_VIEWER_PASSWORD=%s\n' "$(load_password unifi-controller app viewer)"
    printf 'UNIFI_CONTROLLER_HOMEPAGE_PASSWORD=%s\n' "$(load_password unifi-controller app homepage)"
    printf 'UNIFI_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unifi-controller http-proxy status)"
    printf 'UNIFI_CONTROLLER_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password unifi-controller http-proxy prometheus)"

    printf 'VAULTWARDEN_SUPERADMIN_PASSWORD=%s\n' "$(load_password vaultwarden app superadmin)"
    printf 'VAULTWARDEN_ADMIN_PASSWORD=%s\n' "$(load_password vaultwarden app admin)"
    printf 'VAULTWARDEN_HOMELAB_PASSWORD=%s\n' "$(load_password vaultwarden app homelab)"
    printf 'VAULTWARDEN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password vaultwarden http-proxy status)"
    printf 'VAULTWARDEN_PROXY_PROMETHEUS_PASSWORD=%s\n' "$(load_password vaultwarden http-proxy prometheus)"
} >>'.secrets.env'
