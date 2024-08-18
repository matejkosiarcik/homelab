#!/bin/sh
set -euf
# shellcheck disable=SC2248

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

input_dir="$(git rev-parse --show-toplevel)/icons"
global_outdir="$(git rev-parse --show-toplevel)/docker-images/external/homer/assets/icons"
rm -rf "$global_outdir"
mkdir -p "$global_outdir"

# NOTE: 126px is because the border adds 1px on each side -> so the result dimension is 128px
convert_options='magick INPUT_FILE -resize 126x126 -density 1200 -background none -bordercolor transparent -border 1 OUTPUT_FILE'

### OSA Icons ###

outdir="$global_outdir/osa"
convert_image "$convert_options" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$outdir/light-bulb.png"

### VRT Icons ###

outdir="$global_outdir/vrt"
convert_image "$convert_options" "$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Router.svg" "$outdir/router.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Switch 2.svg" "$outdir/switch.png"

### Organizr Icons ###

outdir="$global_outdir/organizr"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/healthchecks.png" "$outdir/healthchecks.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/homeassistant.png" "$outdir/home-assistant.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/netdata.png" "$outdir/netdata.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" "$outdir/pihole.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/speedtest-icon.png" "$outdir/speedtest.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/unifi.png" "$outdir/unifi.png"

### Kubernetes Icons ###

outdir="$global_outdir/kubernetes"

### Other Icons ###

outdir="$global_outdir/other"
convert_image "$convert_options" "$input_dir/other/apple.svg.bin" "$outdir/apple.png"
convert_image "$convert_options" "$input_dir/other/homer.png" "$outdir/homer.png"
convert_image "$convert_options" "$input_dir/other/odroid.png" "$outdir/odroid.png"
convert_image "$convert_options" "$input_dir/other/prometheus.svg.bin" "$outdir/prometheus.png"
convert_image "$convert_options" "$input_dir/other/raspberry-pi.svg.bin" "$outdir/raspberry-pi.png"
convert_image "$convert_options" "$input_dir/other/smtp4dev - custom.png" "$outdir/smtp4dev.png"
convert_image "$convert_options" "$input_dir/other/tp-link-omada.svg.bin" "$outdir/tp-link-omada.png"
convert_image "$convert_options" "$input_dir/other/tp-link.svg.bin" "$outdir/tp-link.png"
convert_image "$convert_options" "$input_dir/other/upc.svg.bin" "$outdir/upc.png"
convert_image "$convert_options" "$input_dir/other/uptime-kuma.svg.bin" "$outdir/uptime-kuma.png"

### Cleanup ###

rm -rf "$tmpdir"
