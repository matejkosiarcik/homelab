#!/bin/sh
set -euf

app_dir_path="$(realpath "${1}")"
output_filepath="$(realpath "${2}")"

# shellcheck source=/dev/null
. "${PWD}/parse-app-entry-utils.sh"

## Get config values for this specific app ##

app_type="$(get_app_type "${app_dir_path}")"

## Get config values for this generic app-type ##

proxy_urls_config="$(yq --raw-output --compact-output '.apache."upstream-url"' "/homelab/docker-compose/${app_type}/config.yml")"
if [ "${proxy_urls_config}" = '' ] || [ "${proxy_urls_config}" = 'null' ] || [ "${proxy_urls_config}" = 'undefined' ]; then
    proxy_urls_config='{}'
fi

favicons_config="$(yq --raw-output --compact-output '.favicons' "/homelab/docker-compose/${app_type}/config.yml")"
if [ "${favicons_config}" = '' ] || [ "${favicons_config}" = 'null' ] || [ "${favicons_config}" = 'undefined' ]; then
    favicons_config='{}'
fi

## Output ##

{
    printf '\n'
    printf '  - app_type: "%s"\n' "${app_type}"
    printf '    proxy_urls: %s\n' "${proxy_urls_config}"
    printf '    favicons: %s\n' "${favicons_config}"
} >>"${output_filepath}"
