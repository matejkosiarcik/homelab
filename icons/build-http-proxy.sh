#!/bin/sh
set -euf

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

input_dir="$(git rev-parse --show-toplevel)/icons"
outdir="$(git rev-parse --show-toplevel)/docker-images/custom/http-proxy/www/.proxy/icons/unifi-controller"
rm -rf "$outdir"
mkdir -p "$outdir"

### Unifi Controller ###

convert_image 'magick -background none -bordercolor transparent INPUT_FILE -resize 32x32 -density 1200 OUTPUT_FILE' "$input_dir/gitman-repositories/homer-icons/svg/ubiquiti.svg" "$outdir/favicon.png"

### Cleanup ###

rm -rf "$tmpdir"
