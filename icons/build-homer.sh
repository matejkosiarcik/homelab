#!/bin/sh
set -euf
# shellcheck disable=SC2248

. "$(dirname "$0")/.build-utils.sh"
indir="$(git rev-parse --show-toplevel)/icons"
global_outdir="$(git rev-parse --show-toplevel)/machines/odroid-h3/homer/config/assets/icons"
rm -rf "$global_outdir"
mkdir -p "$global_outdir"

# NOTE: 126px is because the border adds 1px on each side -> so the result dimension is 128px
convert_options='magick INPUT_FILE -resize 126x126 -density 1200 -background none -bordercolor transparent -border 1 OUTPUT_FILE'

### OSA Icons ###

outdir="$global_outdir/osa"
convert_image "$convert_options" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$outdir/awareness.png"

### VRT Icons ###

outdir="$global_outdir/vrt"
convert_image "$convert_options" "$indir/gitman/dia-vrt-sheets/SVG/VRT Networking & Communications/Router.svg" "$outdir/router.png"
convert_image "$convert_options" "$indir/gitman/dia-vrt-sheets/SVG/VRT Networking & Communications/Switch 2.svg" "$outdir/switch-2.png"

### Organizr Icons ###

outdir="$global_outdir/organizr"
convert_image "$convert_options" "$indir/gitman/organizr/plugins/images/tabs/healthchecks.png" "$outdir/healthchecks.png"
convert_image "$convert_options" "$indir/gitman/organizr/plugins/images/tabs/homeassistant.png" "$outdir/homeassistant.png"
convert_image "$convert_options" "$indir/gitman/organizr/plugins/images/tabs/netdata.png" "$outdir/netdata.png"
convert_image "$convert_options" "$indir/gitman/organizr/plugins/images/tabs/pihole.png" "$outdir/pihole.png"
convert_image "$convert_options" "$indir/gitman/organizr/plugins/images/tabs/speedtest-icon.png" "$outdir/speedtest.png"
convert_image "$convert_options" "$indir/gitman/organizr/plugins/images/tabs/unifi.png" "$outdir/unifi.png"

### Kubernetes Icons ###

outdir="$global_outdir/kubernetes"

### Other Icons ###

outdir="$global_outdir/other"
convert_image "$convert_options" "$indir/other/apple.svg.bin" "$outdir/apple.png"
convert_image "$convert_options" "$indir/other/homer.png" "$outdir/homer.png"
convert_image "$convert_options" "$indir/other/odroid.png" "$outdir/odroid.png"
convert_image "$convert_options" "$indir/other/prometheus.svg.bin" "$outdir/prometheus.png"
convert_image "$convert_options" "$indir/other/raspberry-pi.svg.bin" "$outdir/raspberry-pi.png"
convert_image "$convert_options" "$indir/other/smtp4dev - custom.png" "$outdir/smtp4dev.png"
convert_image "$convert_options" "$indir/other/tp-link-omada.svg.bin" "$outdir/tp-link-omada.png"
convert_image "$convert_options" "$indir/other/tp-link.svg.bin" "$outdir/tp-link.png"
convert_image "$convert_options" "$indir/other/upc.svg.bin" "$outdir/upc.png"
convert_image "$convert_options" "$indir/other/uptime-kuma.svg.bin" "$outdir/uptime-kuma.png"

### Favicon ###

outdir="$global_outdir"
convert_image 'magick INPUT_FILE -resize 16x16 -density 1200 -background none -bordercolor transparent OUTPUT_FILE' "$indir/other/homer.png" "$tmpdir/homer-favicon/homer-16.png"
convert_image 'magick INPUT_FILE -resize 32x32 -density 1200 -background none -bordercolor transparent OUTPUT_FILE' "$indir/other/homer.png" "$tmpdir/homer-favicon/homer-32.png"
convert_ico "$tmpdir/homer-favicon/homer-16.png $tmpdir/homer-favicon/homer-32.png" "$outdir/favicon.ico"

### Cleanup ###

rm -rf "$tmpdir"
