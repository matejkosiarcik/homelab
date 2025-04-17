#!/bin/sh
set -euf

input_dir="$(git rev-parse --show-toplevel)/icons"
output_dir="$(git rev-parse --show-toplevel)/docker-images/custom/http-proxy/www/.proxy/icons/unifi-controller"
rm -rf "$output_dir"
mkdir -p "$output_dir"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

### UniFi Controller ###

# shellcheck disable=SC2034
default_image_size='32x32'
# shellcheck disable=SC2034
default_convert_options='magick -background none INPUT_FILE -resize RESOLUTION -density 1200 OUTPUT_FILE'

convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/ubiquiti.svg" "$output_dir/favicon.png"

### Cleanup ###

rm -rf "$tmpdir"
