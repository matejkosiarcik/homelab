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
    printf '%s\n' "${*}" | while IFS= read -r log_message; do
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
output_dir="$(git rev-parse --show-toplevel)/docker-images/healthchecks/app/icons"
if [ "${only_pattern:-}" = '' ]; then
    rm -rf "${output_dir}"
fi
mkdir -p "${output_dir}"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "${0}")/.build-utils.sh"

# shellcheck disable=SC2034
default_image_size='128x128'
# shellcheck disable=SC2034
default_convert_options='magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 126x126 -density 2000 -border 1 OUTPUT_FILE'

### Dashboard icon ###

convert_image_full "${input_dir}/gitman-repositories/organizr/plugins/images/tabs/healthchecks.png" "${output_dir}/healthchecks.png"

### Cleanup ###

rm -rf "${tmpdir}"
unset tmpdir
