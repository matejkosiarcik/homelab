#!/bin/sh
set -euf

app_dir_path="$(realpath "$1")"
output_filepath="$(realpath "$2")"

# shellcheck source=/dev/null
. "$PWD/parse-app-entry-utils.sh"

## Get config values for this specific app ##

app_type="$(get_app_type "$app_dir_path")"
app_full_name_pretty="$(get_app_full_name_pretty "$app_dir_path")"
app_full_name_machine="$(get_app_full_name_machine "$app_dir_path")"
app_full_name_env="$(get_app_full_name_env "$app_dir_path")"
app_domain="$(get_app_domain "$app_dir_path")"
server_name="$(get_server_name "$app_dir_path")"

## Get config values for this generic app-type ##

gatus_config="$(yq --raw-output --compact-output '.gatus' "/homelab/docker-compose/$app_type/config.yml")"
if [ "$gatus_config" = '' ] || [ "$gatus_config" = 'null' ] || [ "$gatus_config" = 'undefined' ]; then
    gatus_config='{}'
fi

prometheus_config="$(yq --raw-output --compact-output '.prometheus' "/homelab/docker-compose/$app_type/config.yml")"
if [ "$prometheus_config" = '' ] || [ "$prometheus_config" = 'null' ] || [ "$prometheus_config" = 'undefined' ]; then
    prometheus_config='{}'
fi

## Output ##

tmpfile="$(mktemp)"
{
    printf '\n'
    printf '  - app_type: "%s"\n' "$app_type"
    printf '    domain: "%s"\n' "$app_domain"
    printf '    full_name_env: "%s"\n' "$app_full_name_env"
    printf '    full_name_machine: "%s"\n' "$app_full_name_machine"
    printf '    full_name_pretty: "%s"\n' "$app_full_name_pretty"
    printf '    gatus: %s\n' "$gatus_config"
    printf '    prometheus: %s\n' "$prometheus_config"
} >>"$tmpfile"

sed -E "s~<<app-name-pretty>>~$app_full_name_pretty~g;s~<<app-name-machine>>~$app_full_name_machine~g;s~<<app-env>>~$app_full_name_env~g;s~<<server>>~$server_name~g" <"$tmpfile" >>"$output_filepath"
rm -f "$tmpfile"
