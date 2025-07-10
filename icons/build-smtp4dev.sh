#!/bin/sh
set -euf

input_dir="$(git rev-parse --show-toplevel)/icons"
output_dir="$(git rev-parse --show-toplevel)/docker-images/external/smtp4dev/icons"
rm -rf "$output_dir"
mkdir -p "$output_dir"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

# shellcheck disable=SC2034
default_image_size='64x64'
# shellcheck disable=SC2034
default_convert_options='magick -background none -bordercolor transparent INPUT_FILE -resize RESOLUTION -density 1200 OUTPUT_FILE'

### Favicon ###

convert_image_draft 'magick -background none INPUT_FILE -resize 16x16 -density 1200 OUTPUT_FILE' "$input_dir/other/smtp4dev-favicon.png" "$tmpdir/favicon-16.png"
optimize_image "$tmpdir/favicon-16.png"
convert_image_draft 'magick -background none INPUT_FILE -resize 32x32 -density 1200 OUTPUT_FILE' "$input_dir/other/smtp4dev-favicon.png" "$tmpdir/favicon-32.png"
optimize_image "$tmpdir/favicon-32.png"
convert_ico "$tmpdir/favicon-16.png $tmpdir/favicon-32.png" "$output_dir/favicon.ico"

convert_image_full "$input_dir/other/smtp4dev-favicon.png" "$output_dir/favicon.png"

### Cleanup ###

rm -rf "$tmpdir"
