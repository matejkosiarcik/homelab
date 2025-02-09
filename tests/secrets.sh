#!/bin/sh
set -euf

cd "$(dirname "$0")"

if [ "${BW_SESSION-}" = '' ]; then
    echo 'You must set BW_SESSION env variable before calling this script.' >&2
    exit 1
fi

bw sync
rm -f .secrets.env

load_password() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    bw get item "homelab--$1--$2--$3" | jq -er '.login.password'
}

load_notes() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    bw get item "homelab--$1--$2--$3" | jq -er '.notes'
}

{
    printf 'GATUS_2_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 app prometheus)"
    printf 'GATUS_2_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-2 http-proxy status)"
    printf 'GATUS_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus app prometheus)"
    printf 'GATUS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus http-proxy status)"

    printf 'HEALTHCHECKS_PASSWORD=%s\n' "$(load_password healthchecks app admin)"
    printf 'HEALTHCHECKS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password healthchecks http-proxy status)"

    printf 'HOMEASSISTANT_PASSWORD=%s\n' "$(load_password homeassistant app admin)"
    printf 'HOMEASSISTANT_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password homeassistant app prometheus-api-key)"
    printf 'HOMEASSISTANT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password homeassistant http-proxy status)"

    printf 'JELLYFIN_PASSWORD=%s\n' "$(load_password jellyfin app admin)"
    printf 'JELLYFIN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password jellyfin http-proxy status)"

    printf 'MINIO_PASSWORD=%s\n' "$(load_password minio app admin)"
    printf 'MINIO_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password minio app prometheus-token)"
    printf 'MINIO_PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio http-proxy status)"

    printf 'OMADA_CONTROLLER_PASSWORD=%s\n' "$(load_password omada-controller app admin)"
    printf 'OMADA_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password omada-controller http-proxy status)"

    printf 'PIHOLE_1_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-1-primary app admin)"
    printf 'PIHOLE_1_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-primary http-proxy status)"
    printf 'PIHOLE_1_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-1-secondary app admin)"
    printf 'PIHOLE_1_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary http-proxy status)"
    printf 'PIHOLE_2_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-2-primary app admin)"
    printf 'PIHOLE_2_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-primary http-proxy status)"
    printf 'PIHOLE_2_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-2-secondary app admin)"
    printf 'PIHOLE_2_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary http-proxy status)"

    printf 'UNIFI_CONTROLLER_PASSWORD=%s\n' "$(load_password unifi-controller app admin)"
    printf 'UNIFI_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unifi-controller http-proxy status)"
} >>'.secrets.env'
