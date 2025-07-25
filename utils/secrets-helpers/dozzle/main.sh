#!/bin/sh
set -euf

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n' >&2
    printf 'Required: <output-dir>\n' >&2
    exit 1
fi
output_dir="$1"

tmpdir="$(mktemp -d)"

# Custom certificates for agents
openssl genpkey -algorithm RSA -out "$tmpdir/key.pem" -pkeyopt rsa_keygen_bits:2048
openssl req -new -key "$tmpdir/key.pem" -out "$tmpdir/request.csr" -subj "/C=SK/ST=Slovakia/L=Bratislava/O=Homelab"
openssl x509 -req -in "$tmpdir/request.csr" -signkey "$tmpdir/key.pem" -out "$tmpdir/cert.pem" -days 3650
cp "$tmpdir/key.pem" "$output_dir/dozzle-key.pem"
cp "$tmpdir/cert.pem" "$output_dir/dozzle-cert.pem"

rm -rf "$tmpdir"
