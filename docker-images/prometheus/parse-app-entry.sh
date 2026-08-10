#!/bin/sh
set -euf

apppath="$(realpath "$1")"
output="$(realpath "$2")"

## Get config values for this specific app ##

app_shortname="$(basename "$apppath" | sed -E 's~^\.~~')"

app_type="$(yq --raw-output .app.type "$apppath/config/config.yml")"
if [ "$app_type" = '' ] || [ "$app_type" = 'null' ] || [ "$app_type" = 'undefined' ]; then
    app_type="$app_shortname"
fi

app_fullname="$(yq --raw-output .app.fullname "$apppath/config/config.yml")"
if [ "$app_fullname" = '' ] || [ "$app_fullname" = 'null' ] || [ "$app_fullname" = 'undefined' ]; then
    app_fullname="$app_shortname"
fi

domain="$(yq --raw-output .network.domain "$apppath/config/config.yml")"
if [ "$domain" = '' ] || [ "$domain" = 'null' ] || [ "$domain" = 'undefined' ]; then
    domain="$app_fullname.matejhome.com"
fi

app_fullname_uppercase="$(printf '%s' "$app_fullname" | tr '[:lower:]' '[:upper:]')"

## Get config values for this generic app-type ##

prometheus_config="$(yq --raw-output --compact-output .prometheus "/homelab/docker-compose/$app_type/config.yml")"
if [ "$app_type" = '' ] || [ "$app_type" = 'null' ] || [ "$app_type" = 'undefined' ]; then
    prometheus_config="{}"
fi

## Output ##

tmpfile="$(mktemp)"
cat >>"$tmpfile" <<EOF
    - app: "$app_type"
        short_name: "$app_shortname"
        full_name: "$app_fullname"
        domain: "$domain"
        prometheus: $prometheus_config
EOF

unexpand -t 4 <"$tmpfile" | expand -t 2 | sed -E "s~<<app>>~$app_fullname~g;s~<<APP>>~$app_fullname_uppercase~g" >>"$output"
rm -f "$tmpfile"
