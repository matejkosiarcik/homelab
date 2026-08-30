#!/bin/sh
set -euf

app_dir_path="$(realpath "$1")"
output_filepath="$(realpath "$2")"

# shellcheck source=/dev/null
. "$PWD/parse-app-entry-utils.sh"

## Get config values for this specific app ##

app_domain="$(get_app_domain "$app_dir_path")"
app_ip="$(get_app_ip "$app_dir_path")"

printf '%s %s\n' "$app_ip" "$app_domain" >>"$output_filepath"
