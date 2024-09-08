#!/bin/sh
set -euf
# shellcheck disable=SC2248

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

input_dir="$(git rev-parse --show-toplevel)/icons"
outdir="$(git rev-parse --show-toplevel)/docs/diagrams/icons"
rm -rf "$outdir"
mkdir -p "$outdir"

convert_options='magick -background none -bordercolor transparent INPUT_FILE -resize 256x256 -density 1200 OUTPUT_FILE'

### OSA Icons ###

### VRT Icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Wired Segment (Internet).svg" "$outdir/network.png"

### Organizr Icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" "$outdir/pihole.png"

### Kubernetes Icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ing.svg" "$outdir/ingress.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/cronjob.svg" "$outdir/cronjob.png"

### Homer icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/letencrypt.png" "$outdir/lets-encrypt.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/uptimekuma.svg" "$outdir/uptime-kuma.png"

### Other Icons ###

convert_image "$convert_options" "$input_dir/other/apache.svg.bin" "$outdir/apache.png"
convert_image "$convert_options" "$input_dir/other/smtp4dev - custom.png" "$outdir/smtp4dev.png"

## Combined icons ###

convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 256x256 -border 32 -density 1200 OUTPUT_FILE' "$input_dir/gitman-repositories/homer-icons/png/chromium.png" "$tmpdir/chromium.png"
convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 256x256 -border 64 -density 1200 OUTPUT_FILE' "$input_dir/other/playwright.svg.bin" "$tmpdir/playwright.png"
convert_image "magick $tmpdir/chromium.png $tmpdir/playwright.png -gravity Center -geometry 256x256+80+96 -composite -resize 256x256 OUTPUT_FILE" '' "$outdir/chromium+playwright.png"

### Cleanup ###

rm -rf "$tmpdir"
