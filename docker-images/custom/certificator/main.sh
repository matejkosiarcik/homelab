#!/bin/sh
set -euf

if [ "$HOMELAB_ENV" = 'dev' ]; then
    domain='localhost'
    subject_domain="$domain"
else
    domain='home.matejkosiarcik.com'
    subject_domain="*.$domain"
fi

load_certificate='0'
certificate_file='/homelab/certs/fullchain.pem'
if [ -e "$certificate_file" ]; then
    if [ "$(openssl x509 -noout -subject -in "$certificate_file" | sed -E 's~^.*CN\s*=\s*([a-zA-Z0-9*.]+).*$~\1~')" != "$subject_domain" ]; then
        printf 'Loading certificate (wrong domain)\n' >&2
        load_certificate='1'
    elif ! openssl x509 -checkend "$((60 * 60 * 24 * 30))" -noout -in "$certificate_file" >/dev/null; then
        printf 'Loading certificate (renew period)\n' >&2
        load_certificate='1'
    fi
else
    printf 'Loading certificate (not found)\n' >&2
    load_certificate='1'
fi
if [ "$load_certificate" != '1' ]; then
    printf 'Existing certificate is valid\n' >&2
    exit 0
fi

if [ "$HOMELAB_ENV" = 'prod' ]; then
    printf 'Downloading certificate from certbot\n' >&2
    tmpdir="$(mktemp -d)"
    certificate_archive_file="$tmpdir/certificate.tar.xz"
    timeout 45s sh <<EOF
    while ! curl --fail --silent --show-error --output /dev/null --user "viewer:$CERTBOT_VIEWER_PASSWORD" 'https://certbot.home.matejkosiarcik.com/download/certificate.tar.xz'; do
        echo "sleeping"
        sleep 5
    done
EOF
    curl --fail --silent --show-error --output "$certificate_archive_file" --user "viewer:$CERTBOT_VIEWER_PASSWORD" 'https://certbot.home.matejkosiarcik.com/download/certificate.tar.xz'
    find /homelab/certs -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
    tar -xJf "$certificate_archive_file" -C /homelab/certs --strip-components=1
    rm -rf "$tmpdir"
else
    printf 'Creating self-signed certificates\n' >&2
    tmpdir="$(mktemp -d)"

    # Create new certificates
    openssl_subj="/C=SK/ST=Slovakia/L=Bratislava/O=Home/OU=Homelab/CN=localhost"
    openssl genrsa -out "$tmpdir/privkey.pem" 4096
    openssl req -sha256 -new -key "$tmpdir/privkey.pem" -out "$tmpdir/certificate.pem" -subj "$openssl_subj"
    openssl x509 -req -sha256 -days 365 -in "$tmpdir/certificate.pem" -signkey "$tmpdir/privkey.pem" -out "$tmpdir/fullchain.pem"

    mkdir -p /homelab/certs
    find /homelab/certs -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
    find "$tmpdir" -mindepth 1 -maxdepth 1 -type f -exec sh -c 'mv "$1" "/homelab/certs/$(basename "$1")"' - {} \;
    rm -rf "$tmpdir"
fi
