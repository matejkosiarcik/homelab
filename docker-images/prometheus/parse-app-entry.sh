#!/bin/sh
set -euf

apppath="$(realpath "$1")"
output="$(realpath "$2")"
currdir="$(realpath "$PWD")"

## Get config valus for this specific app ##

app_short_name="$(basename "$apppath")"

app_type="$(yq --raw-output .app "$apppath/config/config.yml")"
if [ "$app_type" = '' ] || [ "$app_type" = 'null' ] || [ "$app_type" = 'undefined' ]; then
    app_type="$app_short_name"
fi

domain="$(yq --raw-output .network.domain "$apppath/config/config.yml")"
if [ "$domain" = '' ] || [ "$domain" = 'null' ] || [ "$domain" = 'undefined' ]; then
    domain="$app_short_name.matejhome.com"
fi

app_full_name="$(printf "$domain" | sed -E 's~\..*$~~')"
app_full_name_uppercase="$(printf "$app_full_name" | tr '[:lower:]' '[:upper:]')"

## Get config valus for this generic app-type ##

prometheus_config="$(yq --raw-output --compact-output .prometheus "/homelab//docker-compose/$app_type/config.yml")"
if [ "$app_type" = '' ] || [ "$app_type" = 'null' ] || [ "$app_type" = 'undefined' ]; then
    prometheus_config="{}"
fi

## Output ##

tmpfile="$(mktemp)"
cat >>"$tmpfile" <<EOF
    - app: "$app_type"
        short_name: "$app_short_name"
        full_name: "$app_full_name"
        domain: "$domain"
        prometheus: $prometheus_config
EOF

unexpand -t 4 <"$tmpfile" | expand -t 2 | sed -E "s~<<app>>~$app_full_name~g;s~<<APP>>~$app_full_name_uppercase~g" >>"$output"
rm -f "$tmpfile"
