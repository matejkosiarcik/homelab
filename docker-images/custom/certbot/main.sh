#!/bin/sh
set -euf

domain='home.matejkosiarcik.com'

create_certificate='0'
certificate_file='/homelab/certs/fullchain.pem'
if [ -e "$certificate_file" ]; then
    if [ "$(openssl x509 -noout -subject -in "$certificate_file" | sed -E 's~^subject\s*=\s*CN\s*=\s*~~')" != "*.$domain" ]; then
        printf 'Renewing certificate (wrong domain)\n' >&2
        create_certificate='1'
    elif ! openssl x509 -checkend "$((60 * 60 * 24 * 45))" -noout -in "$certificate_file" >/dev/null; then
        # Certificate is valid for 1.5 months
        printf 'Renewing certificate (renew period)\n' >&2
        create_certificate='1'
    fi
else
    printf 'Renewing certificate (not found)\n' >&2
    create_certificate='1'
fi
if [ "$create_certificate" != '1' ]; then
    printf 'Existing certificate is valid\n' >&2
    exit 0
fi

date +'%Y-%m-%dT%H:%M:%S' >>'/homelab/data/timestamps.log'
if [ "$(wc -l <'/homelab/data/timestamps.log')" -ge '2' ]; then
    current_date_ts="$(date -u -d "$(tail -n 1 <'/homelab/data/timestamps.log')" +'%s')"
    comparator_date_ts="$(date -u -d "$(tail -n 2 <'/homelab/data/timestamps.log' | head -n 1)" +'%s')"
    difference="$((current_date_ts - comparator_date_ts))"
    if [ "$difference" -lt "$((60 * 60))" ]; then # 1 hour
        printf 'There are too many certificate requests in short time, previous %s s ago, stopping\n' "$difference" >&2
        exit 1
    fi
fi

printf 'Checking DNS authentication\n' >&2
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'GET /v2/check %s' "$(date -u -d "$date" +'%s')" | openssl dgst -sha1 -hmac "$WEBSUPPORT_API_SECRET" | sed -E 's~^.* ~~')"
curl -s --fail -X GET \
    -u "$WEBSUPPORT_API_KEY:$websupport_request_signature" \
    -H "Date: $(date -u -d "$date" +'%a, %d %b %Y %H:%M:%S GMT')" \
    'https://rest.websupport.sk/v2/check' >/dev/null

printf 'Loading leftover DNS records\n' >&2
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'GET /v2/service/%s/dns/record %s' "$WEBSUPPORT_SERVICE_ID" "$(date -u -d "$date" +'%s')" | openssl dgst -sha1 -hmac "$WEBSUPPORT_API_SECRET" | sed -E 's~^.* ~~')"
record_ids="$(curl -s --fail -X GET \
    -u "$WEBSUPPORT_API_KEY:$websupport_request_signature" \
    -H 'Accept: application/json' \
    -H "Date: $(date -u -d "$date" +'%a, %d %b %Y %H:%M:%S GMT')" \
    "https://rest.websupport.sk/v2/service/$WEBSUPPORT_SERVICE_ID/dns/record?page=1&rowsPerPage=1000" | jq -r ".data[] | select(.type == \"TXT\") | select(.name == \"_acme-challenge.$domain\") | .id")"

printf '%s\n' "$record_ids" | while read -r record_id; do
    if [ "$record_id" = '' ]; then
        break
    fi
    if [ "$record_id" = 'null' ]; then
        continue
    fi
    printf 'Deleting leftover DNS record %s\n' "$record_id" >&2
    date="$(date +'%Y-%m-%dT%H:%M:%S')"
    websupport_request_signature="$(printf 'DELETE /v2/service/%s/dns/record/%s %s' "$WEBSUPPORT_SERVICE_ID" "$record_id" "$(date -u -d "$date" +'%s')" | openssl dgst -sha1 -hmac "$WEBSUPPORT_API_SECRET" | sed -E 's~^.* ~~')"
    curl -s --fail -X DELETE \
        -u "$WEBSUPPORT_API_KEY:$websupport_request_signature" \
        -H 'Accept: application/json' \
        -H "Date: $(date -u -d "$date" +'%a, %d %b %Y %H:%M:%S GMT')" \
        "https://rest.websupport.sk/v2/service/$WEBSUPPORT_SERVICE_ID/dns/record/$record_id"
done

printf "Creating certificate\n" >&2
tmpdir="$(mktemp -d)"
statusfile="$tmpdir/status.txt"
printf '0\n' >"$statusfile"
test_cert_mode='--test-cert'
# TODO: Remove test-cert-mode on production servers after Let's Encrypt certificates
if [ "$HOMELAB_ENV" = dev ] || [ "$HOMELAB_ENV" = prod ]; then
    test_cert_mode=''
fi
# shellcheck disable=SC2248
certbot certonly --manual --non-interactive --agree-tos \
    --preferred-challenges dns \
    --domain "*.$domain" \
    --email "$CERTBOT_ADMIN_EMAIL" \
    --manual-auth-hook 'sh certbot-hook-before.sh >>/homelab/logs/certbot.log 2>&1' \
    --manual-cleanup-hook 'sh certbot-hook-after.sh >>/homelab/logs/certbot.log 2>&1' \
    $test_cert_mode || printf '%s\n' "$?" >"$statusfile"

certificate_archive_file='/homelab/data/certificate.tar.xz'
if [ "$(cat "$statusfile")" != '0' ]; then
    printf 'Certificate creation failed\n' >&2
else
    printf "Archiving certificate\n" >&2
    tar -chJf /etc/letsencrypt/live/certificate.tar.xz -C /etc/letsencrypt/live --transform="s~^$domain~certificate~" "$domain"
    if [ -e "$certificate_archive_file" ]; then
        rm -rf "$certificate_archive_file"
    fi
    mv '/etc/letsencrypt/live/certificate.tar.xz' "$certificate_archive_file"
    find /homelab/certs -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
    tar -xJf "$certificate_archive_file" -C /homelab/certs --strip-components=1
fi

exit "$(cat "$statusfile")"
