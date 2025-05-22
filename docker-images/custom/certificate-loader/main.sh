#!/bin/sh
set -euf

create_certs='0'

if [ "${HOMELAB_ENV-x}" = 'x' ]; then
    printf 'HOMELAB_ENV unset\n' >&2
    exit 1
fi
if [ "${HOMELAB_APP_EXTERNAL_DOMAIN-x}" = 'x' ]; then
    printf 'HOMELAB_APP_EXTERNAL_DOMAIN unset\n' >&2
    exit 1
fi
if [ "${HOMELAB_APP_EXTERNAL_IP-x}" = 'x' ]; then
    printf 'HOMELAB_APP_EXTERNAL_IP unset\n' >&2
    exit 1
fi

if [ ! -e '/homelab/certs' ]; then
    create_certs='1'
fi

if [ -e '/homelab/certs/domain.txt' ]; then
    old_domain="$(cat '/homelab/certs/domain.txt')"
    if [ "$old_domain" != "$HOMELAB_APP_EXTERNAL_DOMAIN" ]; then
        create_certs='1'
    fi
else
    create_certs='1'
fi
if [ -e '/homelab/certs/ip.txt' ]; then
    old_ip="$(cat '/homelab/certs/ip.txt')"
    if [ "$old_ip" != "$HOMELAB_APP_EXTERNAL_IP" ]; then
        create_certs='1'
    fi
else
    create_certs='1'
fi

if [ -e '/homelab/certs/certificate.key' ] && [ -e '/homelab/certs/certificate.csr' ] && [ -e '/homelab/certs/certificate.crt' ]; then
    # Only renew certificate when it's validity is less than 1 month
    if ! openssl x509 -checkend "$((60 * 60 * 24 * 30))" -noout -in '/homelab/certs/certificate.crt' >/dev/null; then
        create_certs='1'
    fi
else
    create_certs='1'
fi

if [ "$create_certs" = '1' ]; then
    printf 'Creating certificates\n'
    tmpdir="$(mktemp -d)"

    # TODO: Implement Let's encrypt certificates for production
    if [ "$HOMELAB_ENV" = 'dev' ] || [ "$HOMELAB_ENV" = 'prod' ]; then
        # Set main domain
        main_new_domain="$(printf '%s' "$HOMELAB_APP_EXTERNAL_DOMAIN" | sed -E 's~,.*$~~')"
        openssl_subj="/C=SK/ST=Slovakia/L=Bratislava/O=Home/OU=Homelab/CN=$main_new_domain"

        # Set alternative domains
        subjectAltName_domains="$(printf '%s\n' "$HOMELAB_APP_EXTERNAL_DOMAIN" | tr ',' '\n' | sed 's~^~DNS:~' | tr '\n' ',' | sed -E 's~^,~~;s~,$~~')"
        subjectAltName_ips="$(printf '%s\n' "$HOMELAB_APP_EXTERNAL_IP" | tr ',' '\n' | sed 's~^~IP:~' | tr '\n' ',' | sed -E 's~^,~~;s~,$~~')"
        subjectAltName="$subjectAltName_domains,$subjectAltName_ips"

        # Cache current Domains and IPs
        printf '%s\n' "$HOMELAB_APP_EXTERNAL_DOMAIN" >"$tmpdir/domain.txt"
        printf '%s\n' "$HOMELAB_APP_EXTERNAL_IP" >"$tmpdir/ip.txt"

        # Create new certificates
        openssl genrsa -out "$tmpdir/certificate.key" 4096
        openssl rsa -in "$tmpdir/certificate.key" -out "$tmpdir/certificate.key"
        openssl req -sha256 -new -key "$tmpdir/certificate.key" -out "$tmpdir/certificate.csr" -subj "$openssl_subj" -addext "subjectAltName=$subjectAltName"
        openssl x509 -req -sha256 -days 365 -in "$tmpdir/certificate.csr" -signkey "$tmpdir/certificate.key" -out "$tmpdir/certificate.crt" -copy_extensions copyall
    else
        printf 'Unsupported HOMELAB_ENV %s\n' "$HOMELAB_ENV"
        exit 1
    fi

    mkdir -p /homelab/certs
    find /homelab/certs -type f -delete
    find "$tmpdir" -mindepth 1 -maxdepth 1 -type f -exec sh -c 'mv "$1" "/homelab/certs/$(basename "$1")"' - {} \;
    rm -rf "$tmpdir"
fi
