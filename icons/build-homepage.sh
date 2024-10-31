#!/bin/sh
set -euf
# shellcheck disable=SC2248

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

input_dir="$(git rev-parse --show-toplevel)/icons"
outdir="$(git rev-parse --show-toplevel)/docker-images/external/homepage/icons"
rm -rf "$outdir"
mkdir -p "$outdir"

# NOTE: 126px is because the border adds 1px on each side -> so the result dimension is 128px
convert_options='magick -background none -bordercolor transparent INPUT_FILE -resize 126x126 -density 1200 -border 1 OUTPUT_FILE'

### OSA Icons ###

convert_image "$convert_options" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$outdir/lightbulb.png"
convert_image "$convert_options" "$tmpdir/13_05_osa_icons_svg/osa_wireless_network.svg" "$outdir/wifi-ap.png"

### VRT Icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Router.svg" "$outdir/router.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Switch 2.svg" "$outdir/switch.png"

### Dashboard Icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/dashboard-icons/png/homepage.png" "$outdir/homepage.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/dashboard-icons/svg/ntfy.svg" "$outdir/ntfy.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/dashboard-icons/png/openspeedtest.png" "$outdir/openspeedtest.png"

### Organizr Icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/healthchecks.png" "$outdir/healthchecks.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/homeassistant.png" "$outdir/home-assistant.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/netdata.png" "$outdir/netdata.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" "$outdir/pihole.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/speedtest-icon.png" "$outdir/speedtest.png"

### Homer icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/changedetection.png" "$outdir/changedetection.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/apple-alt.png" "$outdir/apple.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" "$outdir/docker.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/jellyfin.svg" "$outdir/jellyfin.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/minio.png" "$outdir/minio.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/omada.png" "$outdir/tp-link-omada.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/tplink.png" "$outdir/tp-link.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/tvheadend.png" "$outdir/tvheadend.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" "$outdir/prometheus.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/ubiquiti.svg" "$outdir/unifi.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/uptimekuma.svg" "$outdir/uptime-kuma.png"

### Other Icons ###

convert_image "$convert_options" "$input_dir/other/actualbudget.png" "$outdir/actualbudget.png"
convert_image "$convert_options" "$input_dir/other/gatus.png" "$outdir/gatus.png"
convert_image "$convert_options" "$input_dir/other/odroid.png" "$outdir/odroid.png"
convert_image "$convert_options" "$input_dir/other/raspberry-pi.svg.bin" "$outdir/raspberry-pi.png"
convert_image "$convert_options" "$input_dir/other/smtp4dev - custom.png" "$outdir/smtp4dev.png"
convert_image "$convert_options" "$input_dir/other/upc.svg.bin" "$outdir/upc.png"

### Cleanup ###

rm -rf "$tmpdir"
