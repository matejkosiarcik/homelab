#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message || [ -n "${log_message}" ]; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

mode=''
only_pattern=''
if [ "${HOMELAB_ENV-}" != '' ]; then
    mode="${HOMELAB_ENV}"
fi
while [ "${#}" -gt 0 ]; do
    case "${1}" in
    -d | --dev)
        mode='dev'
        shift
        ;;
    -p | --prod)
        mode='prod'
        shift
        ;;
    --only)
        only_pattern="${2}"
        shift 2
        ;;
    *)
        log ERROR "$(printf 'Unknown argument %s' "${1}")"
        exit 1
        ;;
    esac
done
HOMELAB_ENV="${mode}"

input_dir="$(git rev-parse --show-toplevel)/icons"
output_dir="$(git rev-parse --show-toplevel)/docker-images/favicons/icons"
if [ "${only_pattern:-}" = '' ]; then
    rm -rf "${output_dir}"
fi
mkdir -p "${output_dir}"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "${0}")/.build-utils.sh"

# shellcheck disable=SC2034
default_image_size='64x64'
# shellcheck disable=SC2034
default_convert_options='magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize RESOLUTION -density 2000 OUTPUT_FILE'

## Dashboard Icons ##

convert_image_full "${input_dir}/gitman-repositories/dashboard-icons/svg/prometheus-node-exporter.svg" "${output_dir}/nodeexporter.png"

## Other ##

convert_image_full "${input_dir}/gitman-repositories/homer-icons/png/docker-moby.png" "${output_dir}/docker-stats.png"
convert_image_full "${tmpdir}/other/renovatebot.png" "${output_dir}/renovatebot.png"
convert_image_full "${input_dir}/gitman-repositories/dashboard-icons/svg/samba-server.svg" "${output_dir}/samba.png"
convert_image_full "${input_dir}/gitman-repositories/dashboard-icons/svg/unbound.svg" "${output_dir}/unbound.png"

## Prebuilds ##

convert_image_full "${input_dir}/prebuild/docker-cache.png" "${output_dir}/docker-cache.png"
convert_image_full "${input_dir}/prebuild/git-cache.png" "${output_dir}/git-cache.png"
convert_image_full "${input_dir}/prebuild/npm-cache.png" "${output_dir}/npm-cache.png"
convert_image_full "${input_dir}/prebuild/ollama.png" "${output_dir}/ollama.png"
convert_image_full "${input_dir}/prebuild/lets-encrypt.png" "${output_dir}/certbot.png"

## Smtp4dev ###

output_dir="$(git rev-parse --show-toplevel)/docker-images/smtp4dev/icons"
convert_image_full "${tmpdir}/other/smtp4dev-favicon.png" "${output_dir}/favicon.png"
convert_image_draft 'magick -background none INPUT_FILE -resize 16x16 -density 1200 OUTPUT_FILE' "${tmpdir}/other/smtp4dev-favicon.png" "${tmpdir}/smtp4dev-favicon-16.png"
optimize_image "${tmpdir}/smtp4dev-favicon-16.png"
convert_image_draft 'magick -background none INPUT_FILE -resize 32x32 -density 1200 OUTPUT_FILE' "${tmpdir}/other/smtp4dev-favicon.png" "${tmpdir}/smtp4dev-favicon-32.png"
optimize_image "${tmpdir}/smtp4dev-favicon-32.png"
convert_ico "${tmpdir}/smtp4dev-favicon-16.png ${tmpdir}/smtp4dev-favicon-32.png" "${output_dir}/favicon.ico"
rm -f "${tmpdir}/smtp4dev-favicon-16.png" "${tmpdir}/smtp4dev-favicon-32.png"

## PreBudget ##

output_dir="$(git rev-parse --show-toplevel)/docker-images/prebudget/icons"
convert_image_full "${input_dir}/prebuild/prebudget.png" "${output_dir}/favicon.png"
convert_image_draft 'magick -background none INPUT_FILE -resize 16x16 -density 1200 OUTPUT_FILE' "${input_dir}/prebuild/prebudget.png" "${tmpdir}/prebudget-favicon-16.png"
optimize_image "${tmpdir}/prebudget-favicon-16.png"
convert_image_draft 'magick -background none INPUT_FILE -resize 32x32 -density 1200 OUTPUT_FILE' "${input_dir}/prebuild/prebudget.png" "${tmpdir}/prebudget-favicon-32.png"
optimize_image "${tmpdir}/prebudget-favicon-32.png"
convert_ico "${tmpdir}/prebudget-favicon-16.png ${tmpdir}/prebudget-favicon-32.png" "${output_dir}/favicon.ico"
rm -f "${tmpdir}/prebudget-favicon-16.png" "${tmpdir}/prebudget-favicon-32.png"

### Cleanup ###

rm -rf "${tmpdir}"
unset tmpdir
