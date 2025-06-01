#!/bin/sh
set -euf

domain='home.matejkosiarcik.com'

load_certificate='0'
certificate_file='/homelab/certs/fullchain.pem'
if [ -e "$certificate_file" ]; then
    if [ "$(openssl x509 -noout -subject -in "$certificate_file" | sed -E 's~^subject\s*=\s*CN\s*=\s*~~')" != "*.$domain" ]; then
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

printf 'Downloading certificate from certbot\n' >&2
tmpdir="$(mktemp -d)"
certificate_archive_file="$tmpdir/certificate.tar.xz"
# TODO: Remove "-k" after Let's Encrypt certificates
curl -L -k -u "viewer:$CERTBOT_VIEWER_PASSWORD" --output "$certificate_archive_file" 'https://certbot.home/download/certificate.tar.xz'
tar -xJf "$certificate_archive_file" -C /homelab/certs --strip-components=1
