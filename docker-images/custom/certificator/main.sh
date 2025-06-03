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
# TODO: Remove "--insecure" after Let's Encrypt certificates
timeout 45s sh <<EOF
while ! curl --insecure --fail --silent --show-error --output /dev/null --user "viewer:$CERTBOT_VIEWER_PASSWORD" 'https://certbot.home.matejkosiarcik.com/download/certificate.tar.xz'; do
    echo "sleeping"
    sleep 5
done
EOF
curl --insecure --fail --silent --show-error --output "$certificate_archive_file" --user "viewer:$CERTBOT_VIEWER_PASSWORD" 'https://certbot.home.matejkosiarcik.com/download/certificate.tar.xz'
find /homelab/certs -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
tar -xJf "$certificate_archive_file" -C /homelab/certs --strip-components=1
