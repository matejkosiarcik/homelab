#!/bin/sh
set -euf

cd "$(git rev-parse --show-toplevel)"

print_help() {
    printf 'bash preinstall.sh [-h]\n'
    printf '\n'
    printf 'Arguments:\n'
    printf ' -h  - Print usage\n'
}

while [ "$#" -gt 0 ]; do
    case "$1" in
    -n)
        # Unused
        shift
        ;;
    -h)
        print_help
        exit 0
        ;;
    *)
        print_help
        exit 1
        ;;
    esac
done

DOMAIN='*.home'
openssl_subj="/C=SK/ST=Slovakia/L=Bratislava/O=Unknown/OU=Org/CN=$DOMAIN"

mkdir -p ./certs
openssl genrsa -out './certs/server.key' 4096
openssl rsa -in './certs/server.key' -out './certs/server.key'
openssl req -sha256 -new -key './certs/server.key' -out './certs/server.csr' -subj "$openssl_subj"
openssl x509 -req -sha256 -days 365 -in './certs/server.csr' -signkey './certs/server.key' -out './certs/server.crt'
