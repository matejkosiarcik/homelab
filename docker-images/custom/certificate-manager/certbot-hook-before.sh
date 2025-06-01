#!/bin/sh
set -euf

if [ "${CERTBOT_REMAINING_CHALLENGES-}" != '0' ]; then
    printf 'There should be 0 remaining challenges, but found: %s\n' "$CERTBOT_REMAINING_CHALLENGES" >&2
    exit 1
fi

printf 'Checking DNS authentication\n' >&2
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'GET /v2/check %s' "$(date -u -d "$date" +'%s')" | openssl dgst -sha1 -hmac "$WEBSUPPORT_API_SECRET" | sed -E 's~^.* ~~')"
curl -s --fail -X GET \
    -u "$WEBSUPPORT_API_KEY:$websupport_request_signature" \
    -H "Date: $(date -u -d "$date" +'%a, %d %b %Y %H:%M:%S GMT')" \
    'https://rest.websupport.sk/v2/check' >/dev/null

printf 'Adding new DNS record\n' >&2
record_payload="{
    \"type\": \"TXT\",
    \"name\": \"_acme-challenge.$(printf '%s' "$CERTBOT_DOMAIN" | sed -E 's~\..+$~~')\",
    \"content\": \"$CERTBOT_VALIDATION\",
    \"ttl\": 1,
    \"priority\": 0,
    \"port\": 0,
    \"weight\": 0
}"
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'POST /v2/service/%s/dns/record %s' "$WEBSUPPORT_SERVICE_ID" "$(date -u -d "$date" +'%s')" | openssl dgst -sha1 -hmac "$WEBSUPPORT_API_SECRET" | sed -E 's~^.* ~~')"
curl -s --fail -X POST \
    -u "$WEBSUPPORT_API_KEY:$websupport_request_signature" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Date: $(date -u -d "$date" +'%a, %d %b %Y %H:%M:%S GMT')" \
    -d "$record_payload" \
    "https://rest.websupport.sk/v2/service/$WEBSUPPORT_SERVICE_ID/dns/record"

# Delay is necessary in order to let DNS record propagate
sleep 20
