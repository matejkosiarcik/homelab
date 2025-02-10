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
    printf 'ACTUALBUDGET_PROXY_STATUS_PASSWORD=%s\n' "$(load_password actualbudget http-proxy status)"
    printf 'ACTUALBUDGET_PUBLIC_PASSWORD=%s\n' "$(load_password actualbudget-public app admin)"
    printf 'ACTUALBUDGET_PUBLIC_PROXY_STATUS_PASSWORD=%s\n' "$(load_password actualbudget-public http-proxy status)"

    printf 'CHANGEDETECTION_PASSWORD=%s\n' "$(load_password changedetection app admin)"
    printf 'CHANGEDETECTION_PROXY_STATUS_PASSWORD=%s\n' "$(load_password changedetection http-proxy status)"

    printf 'GATUS_2_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 app prometheus)"
    printf 'GATUS_2_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-2 http-proxy status)"
    printf 'GATUS_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus app prometheus)"
    printf 'GATUS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus http-proxy status)"

    printf 'HEALTHCHECKS_ADMIN_PASSWORD=%s\n' "$(load_password healthchecks app admin)"
    printf 'HEALTHCHECKS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password healthchecks http-proxy status)"

    printf 'HOMEASSISTANT_ADMIN_PASSWORD=%s\n' "$(load_password homeassistant app admin)"
    printf 'HOMEASSISTANT_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password homeassistant app prometheus-api-key)"
    printf 'HOMEASSISTANT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password homeassistant http-proxy status)"

    printf 'HOMEPAGE_PROXY_STATUS_PASSWORD=%s\n' "$(load_password homepage http-proxy status)"

    printf 'JELLYFIN_ADMIN_PASSWORD=%s\n' "$(load_password jellyfin app admin)"
    printf 'JELLYFIN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password jellyfin http-proxy status)"

    printf 'MINIO_ADMIN_PASSWORD=%s\n' "$(load_password minio app admin)"
    printf 'MINIO_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password minio app prometheus-token)"
    printf 'MINIO_PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio http-proxy status)"

    printf 'NTFY_ADMIN_PASSWORD=%s\n' "$(load_password ntfy app admin)"
    printf 'NTFY_USER_PASSWORD=%s\n' "$(load_password ntfy app user)"
    printf 'NTFY_PUBLISHER_PASSWORD=%s\n' "$(load_password ntfy app publisher)"
    printf 'NTFY_PUBLISHER_TOKEN=%s\n' "$(load_password ntfy app publisher-token)"
    printf 'NTFY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password ntfy http-proxy status)"

    printf 'OMADA_CONTROLLER_ADMIN_PASSWORD=%s\n' "$(load_password omada-controller app admin)"
    printf 'OMADA_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password omada-controller http-proxy status)"

    printf 'OPENSPEEDTEST_PROXY_STATUS_PASSWORD=%s\n' "$(load_password openspeedtest http-proxy status)"

    printf 'PIHOLE_1_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-1-primary app admin)"
    printf 'PIHOLE_1_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-primary http-proxy status)"
    printf 'PIHOLE_1_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-1-secondary app admin)"
    printf 'PIHOLE_1_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary http-proxy status)"
    printf 'PIHOLE_2_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-2-primary app admin)"
    printf 'PIHOLE_2_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-primary http-proxy status)"
    printf 'PIHOLE_2_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-2-secondary app admin)"
    printf 'PIHOLE_2_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary http-proxy status)"

    printf 'SMTP4DEV_PROXY_STATUS_PASSWORD=%s\n' "$(load_password smtp4dev http-proxy status)"

    printf 'SPEEDTEST_TRACKER_ADMIN_PASSWORD=%s\n' "$(load_password speedtest-tracker app admin)"
    printf 'SPEEDTEST_TRACKER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password speedtest-tracker http-proxy status)"

    printf 'TVHEADEND_ADMIN_PASSWORD=%s\n' "$(load_password tvheadend app admin)"
    printf 'TVHEADEND_USER_PASSWORD=%s\n' "$(load_password tvheadend app user)"
    printf 'TVHEADEND_PROXY_STATUS_PASSWORD=%s\n' "$(load_password tvheadend http-proxy status)"

    printf 'UNIFI_CONTROLLER_ADMIN_PASSWORD=%s\n' "$(load_password unifi-controller app admin)"
    printf 'UNIFI_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unifi-controller http-proxy status)"

    printf 'VAULTWARDEN_SUPERADMIN_PASSWORD=%s\n' "$(load_password vaultwarden app superadmin)"
    printf 'VAULTWARDEN_ADMIN_PASSWORD=%s\n' "$(load_password vaultwarden app admin)"
    printf 'VAULTWARDEN_HOMELAB_PASSWORD=%s\n' "$(load_password vaultwarden app homelab)"
    printf 'VAULTWARDEN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password vaultwarden http-proxy status)"
} >>'.secrets.env'
