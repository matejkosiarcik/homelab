#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

if [ "${HOMELAB_ENV}" = 'dev' ]; then
    domain='localhost'
    subject_domain="${domain}"
else
    domain='matejhome.com'
    subject_domain="*.${domain}"
fi

load_certificate='0'
certificate_file='/homelab/certs/fullchain.pem'
if [ -e "${certificate_file}" ]; then
    if [ "$(openssl x509 -noout -subject -in "${certificate_file}" | sed -E 's~^.*CN\s*=\s*([a-zA-Z0-9*.]+).*$~\1~')" != "${subject_domain}" ]; then
        printf '%s [INFO]: Loading certificate (previous certificate has wrong domain)\n' "$(date "${datetime_format}")" >&2
        load_certificate='1'
    elif ! openssl x509 -checkend "$((60 * 60 * 24 * 30))" -noout -in "${certificate_file}" >'/dev/null'; then
        printf '%s [INFO]: Loading certificate (previous certificate is about to expire)\n' "$(date "${datetime_format}")" >&2
        load_certificate='1'
    elif [ "${HOMELAB_ENV}" = 'prod' ] && [ "$(openssl x509 -noout -issuer -in "${certificate_file}" | sed -E 's~^issuer=~~')" = "$(openssl x509 -noout -subject -in "${certificate_file}" | sed -E 's~^subject=~~')" ]; then
        printf '%s [INFO]: Loading certificate (previous certificate is self-signed)\n' "$(date "${datetime_format}")" >&2
        load_certificate='1'
    fi
else
    printf '%s [INFO]: Loading certificate (previous certificate not found)\n' "$(date "${datetime_format}")" >&2
    load_certificate='1'
fi
if [ "${load_certificate}" != '1' ]; then
    printf '%s [INFO]: Existing certificate is valid\n' "$(date "${datetime_format}")" >&2
    exit 0
fi

get_dev_certificate() {
    printf '%s [INFO]: Creating self-signed certificates\n' "$(date "${datetime_format}")" >&2
    tmpdir="$(mktemp -d)"

    # Create new certificates
    openssl_subj="/C=SK/ST=Slovakia/L=Bratislava/O=Home/OU=Homelab/CN=${subject_domain}"
    openssl genrsa -out "${tmpdir}/privkey.pem" 4096
    openssl req -sha256 -new -key "${tmpdir}/privkey.pem" -out "${tmpdir}/certificate.pem" -subj "${openssl_subj}"
    openssl x509 -req -sha256 -days 365 -in "${tmpdir}/certificate.pem" -signkey "${tmpdir}/privkey.pem" -out "${tmpdir}/fullchain.pem"

    # Copy certificates to proper directory
    mkdir -p '/homelab/certs'
    find '/homelab/certs' -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
    find "${tmpdir}" -mindepth 1 -maxdepth 1 -type f -exec sh -c 'mv "${1}" "/homelab/certs/$(basename "${1}")"' - {} \;

    # Cleanup
    rm -rf "${tmpdir}"
}

get_prod_certificate() {
    printf '%s [INFO]: Downloading certificates from certbot\n' "$(date "${datetime_format}")" >&2
    tmpdir="$(mktemp -d)"

    # Download certificates
    curl --fail --silent --show-error --output "${tmpdir}/certificate.tar.xz" --user "homelab-viewer:${CERTBOT_HOMELAB_VIEWER_PASSWORD}" 'https://certbot.matejhome.com/download/certificate.tar.xz'

    # Extract certificates
    mkdir -p "${tmpdir}/certs"
    tar -xJf "${tmpdir}/certificate.tar.xz" -C "${tmpdir}/certs" --strip-components=1

    # Copy certificates to proper directory
    mkdir -p '/homelab/certs'
    find '/homelab/certs' -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
    find "${tmpdir}/certs" -mindepth 1 -maxdepth 1 -type f -exec sh -c 'mv "${1}" "/homelab/certs/$(basename "${1}")"' - {} \;

    # Cleanup
    rm -rf "${tmpdir}"
}

check_certbot_availability() {
    printf '%s [INFO]: Checking certbot availability\n' "$(date "${datetime_format}")" >&2
    timeout 45s sh <<EOF
    while ! curl --fail --silent --show-error --output '/dev/null' --user "homelab-viewer:${CERTBOT_HOMELAB_VIEWER_PASSWORD}" 'https://certbot.matejhome.com/download/certificate.tar.xz'; do
        sleep 5
    done
EOF
}

if [ "${HOMELAB_ENV}" = 'prod' ]; then
    # Get production certificate if available, otherwise create temporary development certificate
    if check_certbot_availability; then
        get_prod_certificate
    else
        get_dev_certificate
    fi
else
    printf '%s [INFO]: Creating self-signed certificates\n' "$(date "${datetime_format}")" >&2
    get_dev_certificate
fi
