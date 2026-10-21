#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

if [ "${CERTBOT_REMAINING_CHALLENGES-}" != '0' ]; then
    printf '%s [ERROR]: There should be 0 remaining challenges, but found: %s\n' "$(date "${datetime_format}")" "${CERTBOT_REMAINING_CHALLENGES}" >&2
    exit 1
fi

printf '%s [INFO]: Checking DNS authentication\n' "$(date "${datetime_format}")" >&2
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'GET /v2/check %s' "$(date -u -d "${date}" +'%s')" | openssl dgst -sha1 -hmac "${WEBSUPPORT_API_SECRET}" | sed -E 's~^.* ~~')"
curl -s --fail -X GET \
    -u "${WEBSUPPORT_API_KEY}:${websupport_request_signature}" \
    -H "Date: $(date -u -d "${date}" +'%a, %d %b %Y %H:%M:%S GMT')" \
    'https://rest.websupport.sk/v2/check' >'/dev/null'

# This is for 4th degree subdomains "_acme-challenge.$(printf '%s' "${CERTBOT_DOMAIN}" | sed -E 's~\..+$~~')"
printf '%s [INFO]: Adding new DNS record\n' "$(date "${datetime_format}")" >&2
record_payload="{
    \"type\": \"TXT\",
    \"name\": \"_acme-challenge\",
    \"content\": \"${CERTBOT_VALIDATION}\",
    \"ttl\": 1,
    \"priority\": 0,
    \"port\": 0,
    \"weight\": 0
}"
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'POST /v2/service/%s/dns/record %s' "${WEBSUPPORT_SERVICE_ID}" "$(date -u -d "${date}" +'%s')" | openssl dgst -sha1 -hmac "${WEBSUPPORT_API_SECRET}" | sed -E 's~^.* ~~')"
curl -s --fail -X POST \
    -u "${WEBSUPPORT_API_KEY}:${websupport_request_signature}" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Date: $(date -u -d "${date}" +'%a, %d %b %Y %H:%M:%S GMT')" \
    -d "${record_payload}" \
    "https://rest.websupport.sk/v2/service/${WEBSUPPORT_SERVICE_ID}/dns/record"

# Delay is necessary to let DNS record propagate
sleep 45
