#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message || [ -n "${log_message}" ]; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

domain='matejhome.com'
certificate_file='/homelab/certs/fullchain.pem'
certificate_archive_file='/homelab/data/certificate.tar.xz'

create_certificate='0'
if [ -e "${certificate_file}" ]; then
    if [ "$(openssl x509 -noout -subject -in "${certificate_file}" | sed -E 's~^subject\s*=\s*CN\s*=\s*~~')" != "*.${domain}" ]; then
        log INFO 'Renewing certificate (wrong domain)'
        create_certificate='1'
    elif ! openssl x509 -checkend "$((60 * 60 * 24 * 45))" -noout -in "${certificate_file}" >'/dev/null'; then
        # Certificate is valid for 1.5 months
        log INFO 'Renewing certificate (renew period)'
        create_certificate='1'
    fi
else
    log INFO 'Renewing certificate (not found)'
    create_certificate='1'
fi
if [ "${create_certificate}" != '1' ]; then
    log INFO 'Existing certificate is valid'
    exit 0
fi

if [ -e "${certificate_archive_file}" ]; then
    tmpdir="$(mktemp -d)"
    tar -xJf "${certificate_archive_file}" -C "${tmpdir}" --strip-components=1
    tmp_certificate_file="${tmpdir}/fullchain.pem"

    certificate_valid='1'
    if [ "$(openssl x509 -noout -subject -in "${tmp_certificate_file}" | sed -E 's~^subject\s*=\s*CN\s*=\s*~~')" != "*.${domain}" ]; then
        log INFO 'Renewing certificate archive (wrong domain)'
        certificate_valid='0'
    elif ! openssl x509 -checkend "$((60 * 60 * 24 * 45))" -noout -in "${tmp_certificate_file}" >'/dev/null'; then
        # Certificate is valid for 1.5 months
        log INFO 'Renewing certificate archive (renew period)'
        certificate_valid='0'
    fi

    if [ "${certificate_valid}" = '1' ]; then
        log INFO 'Existing certificate archive is valid'
        mkdir -p '/homelab/certs'
        find '/homelab/certs' -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
        tar -xJf "${certificate_archive_file}" -C '/homelab/certs' --strip-components=1
        rm -rf "${tmpdir}"
        exit 0
    fi
fi

date +'%Y-%m-%dT%H:%M:%S' >>'/homelab/data/timestamps.log'
if [ "$(wc -l <'/homelab/data/timestamps.log')" -ge '2' ]; then
    current_date_ts="$(date -u -d "$(tail -n 1 <'/homelab/data/timestamps.log')" +'%s')"
    comparator_date_ts="$(date -u -d "$(tail -n 2 <'/homelab/data/timestamps.log' | head -n 1)" +'%s')"
    difference="$((current_date_ts - comparator_date_ts))"
    if [ "${difference}" -lt "$((60 * 60))" ]; then # 1 hour
        log ERROR "$(printf 'There are too many certificate requests in short time, previous %s s ago, stopping' "${difference}")"
        exit 1
    fi
fi

log INFO 'Checking DNS authentication'
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'GET /v2/check %s' "$(date -u -d "${date}" +'%s')" | openssl dgst -sha1 -hmac "${WEBSUPPORT_API_SECRET}" | sed -E 's~^.* ~~')"
curl -s --fail -X GET \
    -u "${WEBSUPPORT_API_KEY}:${websupport_request_signature}" \
    -H "Date: $(date -u -d "${date}" +'%a, %d %b %Y %H:%M:%S GMT')" \
    'https://rest.websupport.sk/v2/check' >'/dev/null'

log INFO 'Loading leftover DNS records'
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'GET /v2/service/%s/dns/record %s' "${WEBSUPPORT_SERVICE_ID}" "$(date -u -d "${date}" +'%s')" | openssl dgst -sha1 -hmac "${WEBSUPPORT_API_SECRET}" | sed -E 's~^.* ~~')"
record_ids="$(curl -s --fail -X GET \
    -u "${WEBSUPPORT_API_KEY}:${websupport_request_signature}" \
    -H 'Accept: application/json' \
    -H "Date: $(date -u -d "${date}" +'%a, %d %b %Y %H:%M:%S GMT')" \
    "https://rest.websupport.sk/v2/service/${WEBSUPPORT_SERVICE_ID}/dns/record?page=1&rowsPerPage=1000" | jq -r ".data[] | select(.type == \"TXT\") | select(.name == \"_acme-challenge.${domain}\") | .id")"

printf '%s\n' "${record_ids}" | while read -r record_id; do
    if [ "${record_id}" = '' ]; then
        break
    fi
    if [ "${record_id}" = 'null' ]; then
        continue
    fi
    log INFO "$(printf 'Deleting leftover DNS record %s' "${record_id}")"
    date="$(date +'%Y-%m-%dT%H:%M:%S')"
    websupport_request_signature="$(printf 'DELETE /v2/service/%s/dns/record/%s %s' "${WEBSUPPORT_SERVICE_ID}" "${record_id}" "$(date -u -d "${date}" +'%s')" | openssl dgst -sha1 -hmac "${WEBSUPPORT_API_SECRET}" | sed -E 's~^.* ~~')"
    curl -s --fail -X DELETE \
        -u "${WEBSUPPORT_API_KEY}:${websupport_request_signature}" \
        -H 'Accept: application/json' \
        -H "Date: $(date -u -d "${date}" +'%a, %d %b %Y %H:%M:%S GMT')" \
        "https://rest.websupport.sk/v2/service/${WEBSUPPORT_SERVICE_ID}/dns/record/${record_id}"
done

log INFO 'Creating certificate'
tmpdir="$(mktemp -d)"
statusfile="${tmpdir}/status.txt"
printf '0\n' >"${statusfile}"
test_cert_mode='--test-cert'
if [ "${HOMELAB_ENV}" = prod ]; then
    test_cert_mode=''
fi
# shellcheck disable=SC2248
certbot certonly --manual --non-interactive --agree-tos \
    --preferred-challenges dns \
    --domain "*.${domain}" \
    --email "${CERTBOT_PUBLIC_EMAIL}" \
    --manual-auth-hook "sh './certbot-hook-before.sh' >>'/homelab/logs/certbot-hooks.log' 2>&1" \
    --manual-cleanup-hook "sh './certbot-hook-after.sh' >>'/homelab/logs/certbot-hooks.log' 2>&1" \
    ${test_cert_mode} || printf '%s\n' "${?}" >"${statusfile}"

if [ "$(cat "${statusfile}")" != '0' ]; then
    log ERROR 'Certificate creation failed'
    exit "$(cat "${statusfile}")"
else
    log INFO 'Archiving certificate'
    tar -chJf '/etc/letsencrypt/live/certificate.tar.xz' -C '/etc/letsencrypt/live' --transform="s~^${domain}~certificate~" "${domain}"
    if [ -e "${certificate_archive_file}" ]; then
        rm -rf "${certificate_archive_file}"
    fi
    mv '/etc/letsencrypt/live/certificate.tar.xz' "${certificate_archive_file}"
    mkdir -p '/homelab/certs'
    find '/homelab/certs' -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
    tar -xJf "${certificate_archive_file}" -C '/homelab/certs' --strip-components=1
fi

## Cleanup TXT records ##
log INFO 'Loading created DNS records'
date="$(date +'%Y-%m-%dT%H:%M:%S')"
websupport_request_signature="$(printf 'GET /v2/service/%s/dns/record %s' "${WEBSUPPORT_SERVICE_ID}" "$(date -u -d "${date}" +'%s')" | openssl dgst -sha1 -hmac "${WEBSUPPORT_API_SECRET}" | sed -E 's~^.* ~~')"
record_ids="$(curl -s --fail -X GET \
    -u "${WEBSUPPORT_API_KEY}:${websupport_request_signature}" \
    -H 'Accept: application/json' \
    -H "Date: $(date -u -d "${date}" +'%a, %d %b %Y %H:%M:%S GMT')" \
    "https://rest.websupport.sk/v2/service/${WEBSUPPORT_SERVICE_ID}/dns/record?page=1&rowsPerPage=1000" |
    jq -r ".data[] | select(.type == \"TXT\") | select(.name == \"_acme-challenge.${domain}\") | .id")"

printf '%s\n' "${record_ids}" | while read -r record_id; do
    if [ "${record_id}" = '' ]; then
        break
    fi
    if [ "${record_id}" = 'null' ]; then
        continue
    fi
    log INFO "$(printf 'Deleting created DNS record %s' "${record_id}")"
    date="$(date +'%Y-%m-%dT%H:%M:%S')"
    websupport_request_signature="$(printf 'DELETE /v2/service/%s/dns/record/%s %s' "${WEBSUPPORT_SERVICE_ID}" "${record_id}" "$(date -u -d "${date}" +'%s')" | openssl dgst -sha1 -hmac "${WEBSUPPORT_API_SECRET}" | sed -E 's~^.* ~~')"
    curl -s --fail -X DELETE \
        -u "${WEBSUPPORT_API_KEY}:${websupport_request_signature}" \
        -H 'Accept: application/json' \
        -H "Date: $(date -u -d "${date}" +'%a, %d %b %Y %H:%M:%S GMT')" \
        "https://rest.websupport.sk/v2/service/${WEBSUPPORT_SERVICE_ID}/dns/record/${record_id}"
done

exit "$(cat "${statusfile}")"
