#!/bin/sh
set -euf

# shellcheck source=/dev/null
. /app/.internal/cron.env

if [ -z "${HOST+x}" ]; then
    printf 'Apache HOST unset\n'
    exit 4
fi

create_certs='0'

if [ ! -e '/certs' ]; then
    create_certs='1'
fi

if [ -e '/certs/domain.txt' ]; then
    old_domain="$(cat '/certs/domain.txt')"
    if [ "$HOST" != "$old_domain" ]; then
        create_certs='1'
    fi
else
    create_certs='1'
fi

if [ -e '/certs/certificate.key' ] && [ -e '/certs/certificate.csr' ] && [ -e '/certs/certificate.crt' ]; then
    # Only renew certificate when it's validity is less than 1 month
    if ! openssl x509 -checkend "$((60*60*24*30))" -noout -in '/certs/certificate.crt' >/dev/null; then
        create_certs='1'
    fi
else
    create_certs='1'
fi

if [ "$create_certs" = '1' ]; then
    printf 'Creating certificates\n'
    tmpdir="$(mktemp -d)"

    if [ "$ENV" = 'dev' ] || [ "$ENV" = 'prod' ]; then
        openssl_subj="/C=SK/ST=Slovakia/L=Bratislava/O=Unknown/OU=Org/CN=$HOST"
        printf '%s\n' "$HOST" >"$tmpdir/domain.txt"
        openssl genrsa -out "$tmpdir/certificate.key" 4096
        openssl rsa -in "$tmpdir/certificate.key" -out "$tmpdir/certificate.key"
        openssl req -sha256 -new -key "$tmpdir/certificate.key" -out "$tmpdir/certificate.csr" -subj "$openssl_subj"
        openssl x509 -req -sha256 -days 365 -in "$tmpdir/certificate.csr" -signkey "$tmpdir/certificate.key" -out "$tmpdir/certificate.crt"
    else
        printf 'Unsupported ENV %s\n' "$ENV"
        exit 5
    fi

    mkdir -p /certs
    find /certs -type f -delete
    find "$tmpdir" -type f -mindepth 1 -maxdepth 1 -exec sh -c 'mv "$1" "/certs/$(basename "$1")"' - {} \;
    rm -rf "$tmpdir"
fi
