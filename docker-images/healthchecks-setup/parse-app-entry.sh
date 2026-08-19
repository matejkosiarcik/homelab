#!/bin/sh
set -euf

app_dirpath="$(realpath "$1")"
output_filepath="$(realpath "$2")"

. "$PWD/parse-app-entry-utils.sh"

## Get config values for this specific app ##

app_type="$(get_app_type)"
app_full_name_pretty="$(get_app_full_name_pretty)"
app_full_name_machine="$(get_app_full_name_machine)"
app_full_name_env="$(get_app_full_name_env)"
app_domain="$(get_app_domain)"
server_name="$(get_server_name)"

## Get config values for this generic app-type ##

healthchecks_config="$(yq --raw-output --compact-output '.healthchecks' "/homelab/docker-compose/$app_type/config.yml")"
if [ "$healthchecks_config" = '' ] || [ "$healthchecks_config" = 'null' ] || [ "$healthchecks_config" = 'undefined' ]; then
    healthchecks_config='[]'
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
    printf '    healthchecks: %s\n' "$healthchecks_config"
} >>"$tmpfile"

replace_placeholders "$tmpfile" >>"$output_filepath"
rm -f "$tmpfile"
