#!/bin/sh
set -euf

apppath="$(realpath "$1")"
output="$(realpath "$2")"
currdir="$(realpath "$PWD")"

cd "$apppath"

appname="$(basename "$apppath")"

domain="$(yq --raw-output .network.domain './config/config.yml')"
if [ "$domain" = '' ] || [ "$domain" = 'null' ] || [ "$domain" = 'undefined' ]; then
    domain="$appname.matejhome.com"
fi

ip="$(yq --raw-output .network.ip './config/config.yml')"
if [ "$ip" = '' ] || [ "$ip" = 'null' ] || [ "$ip" = 'undefined' ]; then
    ip="0.0.0.0"
fi

printf '%s %s\n' "$ip" "$domain" >>"$output"

cd "$currdir"
