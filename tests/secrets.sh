#!/bin/sh
set -euf

cd "$(dirname "$0")"
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

printf 'GATUS_2_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus-2 app prometheus)" >>'.secrets.env'
printf 'GATUS_2_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus-2 http-proxy status)" >>'.secrets.env'
printf 'GATUS_PROMETHEUS_PASSWORD=%s\n' "$(load_password gatus app prometheus)" >>'.secrets.env'
printf 'GATUS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password gatus http-proxy status)" >>'.secrets.env'

printf 'HEALTHCHECKS_PASSWORD=%s\n' "$(load_password healthchecks app admin)" >>'.secrets.env'
printf 'HEALTHCHECKS_PROXY_STATUS_PASSWORD=%s\n' "$(load_password healthchecks http-proxy status)" >>'.secrets.env'

printf 'HOMEASSISTANT_PASSWORD=%s\n' "$(load_password homeassistant app admin)" >>'.secrets.env'
printf 'HOMEASSISTANT_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password homeassistant app prometheus-api-key)" >>'.secrets.env'
printf 'HOMEASSISTANT_PROXY_STATUS_PASSWORD=%s\n' "$(load_password homeassistant http-proxy status)" >>'.secrets.env'

printf 'JELLYFIN_PASSWORD=%s\n' "$(load_password jellyfin app admin)" >>'.secrets.env'
printf 'JELLYFIN_PROXY_STATUS_PASSWORD=%s\n' "$(load_password jellyfin http-proxy status)" >>'.secrets.env'

printf 'MINIO_PASSWORD=%s\n' "$(load_password minio app admin)" >>'.secrets.env'
printf 'MINIO_PROMETHEUS_BEARER_TOKEN=%s\n' "$(load_password minio app prometheus-token)" >>'.secrets.env'
printf 'MINIO_PROXY_STATUS_PASSWORD=%s\n' "$(load_password minio http-proxy status)" >>'.secrets.env'

printf 'OMADA_CONTROLLER_PASSWORD=%s\n' "$(load_password omada-controller app admin)" >>'.secrets.env'
printf 'OMADA_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password omada-controller http-proxy status)" >>'.secrets.env'

printf 'PIHOLE_1_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-1-primary app admin)" >>'.secrets.env'
printf 'PIHOLE_1_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-primary http-proxy status)" >>'.secrets.env'
printf 'PIHOLE_1_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-1-secondary app admin)" >>'.secrets.env'
printf 'PIHOLE_1_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-1-secondary http-proxy status)" >>'.secrets.env'
printf 'PIHOLE_2_PRIMARY_PASSWORD=%s\n' "$(load_password pihole-2-primary app admin)" >>'.secrets.env'
printf 'PIHOLE_2_PRIMARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-primary http-proxy status)" >>'.secrets.env'
printf 'PIHOLE_2_SECONDARY_PASSWORD=%s\n' "$(load_password pihole-2-secondary app admin)" >>'.secrets.env'
printf 'PIHOLE_2_SECONDARY_PROXY_STATUS_PASSWORD=%s\n' "$(load_password pihole-2-secondary http-proxy status)" >>'.secrets.env'

printf 'UNIFI_CONTROLLER_PASSWORD=%s\n' "$(load_password unifi-controller app admin)" >>'.secrets.env'
printf 'UNIFI_CONTROLLER_PROXY_STATUS_PASSWORD=%s\n' "$(load_password unifi-controller http-proxy status)" >>'.secrets.env'
