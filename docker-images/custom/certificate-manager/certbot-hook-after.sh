#!/bin/sh
set -euf

printf 'Loading created DNS records\n' >&2
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'GET /v2/service/%s/dns/record %s' "$WEBSUPPORT_SERVICE_ID" "$(date -u -d "$date" +'%s')" | openssl dgst -sha1 -hmac "$WEBSUPPORT_API_SECRET" | sed -E 's~^.* ~~')"
record_ids="$(curl -s --fail -X GET \
    -u "$WEBSUPPORT_API_KEY:$websupport_request_signature" \
    -H "Accept: application/json" \
    -H "Date: $(date -u -d "$date" +'%a, %d %b %Y %H:%M:%S GMT')" \
    "https://rest.websupport.sk/v2/service/$WEBSUPPORT_SERVICE_ID/dns/record?page=1&rowsPerPage=1000" |
    jq -r ".data[] | select(.type == \"TXT\") | select(.name == \"_acme-challenge.$CERTBOT_DOMAIN\") | .id")"

printf '%s\n' "$record_ids" | while read -r record_id; do
    if [ "$record_id" = '' ]; then
        break
    fi
    if [ "$record_id" = 'null' ]; then
        continue
    fi
    printf 'Deleting created DNS record %s\n' "$record_id" >&2
    date="$(date +'%Y-%m-%dT%H:%M:%S')"
    websupport_request_signature="$(printf 'DELETE /v2/service/%s/dns/record/%s %s' "$WEBSUPPORT_SERVICE_ID" "$record_id" "$(date -u -d "$date" +'%s')" | openssl dgst -sha1 -hmac "$WEBSUPPORT_API_SECRET" | sed -E 's~^.* ~~')"
    curl -s --fail -X DELETE \
        -u "$WEBSUPPORT_API_KEY:$websupport_request_signature" \
        -H "Accept: application/json" \
        -H "Date: $(date -u -d "$date" +'%a, %d %b %Y %H:%M:%S GMT')" \
        "https://rest.websupport.sk/v2/service/$WEBSUPPORT_SERVICE_ID/dns/record/$record_id"
done
