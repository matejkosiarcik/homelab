#!/bin/sh
set -euf

input_dir="$(git rev-parse --show-toplevel)/icons"
output_dir="$(git rev-parse --show-toplevel)/docker-images/custom/http-proxy/www/.proxy/icons"
rm -rf "$output_dir"
mkdir -p "$output_dir"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

### UniFi Controller ###

# shellcheck disable=SC2034
default_image_size='64x64'
# shellcheck disable=SC2034
default_convert_options='magick -background none INPUT_FILE -resize RESOLUTION -density 1200 OUTPUT_FILE'

convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/ubiquiti.svg" "$output_dir/unifi-controller/favicon.png"

### Certbot ###

# PNG
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/lets-encrypt-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/lets-encrypt-background-mask.png"
magick "$tmpdir/lets-encrypt-background.png" "$tmpdir/lets-encrypt-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/lets-encrypt-background.png"
magick "$tmpdir/lets-encrypt-background.png" -define png:color-type=6 "$tmpdir/lets-encrypt-background.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/lets-encrypt.svg" -resize '56x56' -density 1200 "$tmpdir/lets-encrypt-tmp.png"
magick "$tmpdir/lets-encrypt-background.png" "$tmpdir/lets-encrypt-tmp.png" -gravity Center -composite "$tmpdir/lets-encrypt-final.png"
convert_image_full "$tmpdir/lets-encrypt-final.png" "$output_dir/certbot/favicon.png"

# ICO
convert_image_draft 'magick -background none INPUT_FILE -resize 16x16 -density 1200 OUTPUT_FILE' "$output_dir/certbot/favicon.png" "$tmpdir/lets-encrypt-16.png"
optimize_image "$tmpdir/lets-encrypt-16.png"
convert_image_draft 'magick -background none INPUT_FILE -resize 32x32 -density 1200 OUTPUT_FILE' "$output_dir/certbot/favicon.png" "$tmpdir/lets-encrypt-32.png"
optimize_image "$tmpdir/lets-encrypt-32.png"
convert_ico "$tmpdir/lets-encrypt-16.png $tmpdir/lets-encrypt-32.png" "$output_dir/certbot/favicon.ico"

### Cleanup ###

rm -rf "$tmpdir"
