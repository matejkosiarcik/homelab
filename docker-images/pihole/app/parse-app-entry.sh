#!/bin/sh
set -euf

app_dirpath="$(realpath "$1")"
output_filepath="$(realpath "$2")"

# shellcheck source=/dev/null
. "$PWD/parse-app-entry-utils.sh"

## Get config values for this specific app ##

app_domain="$(get_app_domain "$app_dirpath")"
app_ip="$(get_app_ip "$app_dirpath")"

printf '%s %s\n' "$app_ip" "$app_domain" >>"$output_filepath"
