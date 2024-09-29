#!/bin/sh
set -euf

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

input_dir="$(git rev-parse --show-toplevel)/icons"
outdir="$(git rev-parse --show-toplevel)/docker-images/external/healthchecks/icons"
rm -rf "$outdir"
mkdir -p "$outdir"

# NOTE: 126px is because the border adds 1px on each side -> so the result dimension is 128px
convert_options='magick -background none -bordercolor transparent INPUT_FILE -resize 126x126 -density 1200 -border 1 OUTPUT_FILE'

### Dashboard icon ###

convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/healthchecks.png" "$outdir/healthchecks.png"

### Cleanup ###

rm -rf "$tmpdir"
