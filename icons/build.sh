#!/bin/sh
set -euf
# shellcheck disable=SC2248

PATH="$PATH:$(dirname "$0")/node_modules/.bin"

global_indir="$(git rev-parse --show-toplevel)/icons"
global_outdir="$(git rev-parse --show-toplevel)/machines/odroid-h3/homer/config/assets/icons"
rm -rf "$global_outdir"
mkdir -p "$global_outdir"

# NOTE: 126px is because the border adds 1px on each side -> so the result dimension is 128px
convert_options='-resize 126x126 -density 1200 -background none -bordercolor transparent -border 1'
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/file"

convert_file() {
    command="$1"
    _infile="$tmpdir/file/$(basename "$2" .bin)"
    cp "$2" "$_infile"
    _outfile="$3"
    $command "$_infile" "$_outfile"
    rm -f "$_infile"
    zopflipng --iterations=200 --filters=01234mepb --lossy_8bit --lossy_transparent -y "$_outfile" "$_outfile"
}

### OSA Icons ###

outdir="$global_outdir/osa"
mkdir -p "$outdir"
unzip -q 13_05_osa_icons_svg.zip -d "$tmpdir/13_05_osa_icons_svg"

convert_file "convert $convert_options" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$outdir/awareness.png"

rm -rf "$tmpdir/13_05_osa_icons_svg"

### VRT Icons ###

outdir="$global_outdir/vrt"
mkdir -p "$outdir"

convert_file "convert $convert_options" "$global_indir/gitman/dia-vrt-sheets/SVG/VRT Networking & Communications/Router.svg" "$outdir/router.png"
convert_file "convert $convert_options" "$global_indir/gitman/dia-vrt-sheets/SVG/VRT Networking & Communications/Switch 2.svg" "$outdir/switch-2.png"

### Organizr Icons ###

outdir="$global_outdir/organizr"
mkdir -p "$outdir"

convert_file "convert $convert_options" "$global_indir/gitman/organizr/plugins/images/tabs/healthchecks.png" "$outdir/healthchecks.png"
convert_file "convert $convert_options" "$global_indir/gitman/organizr/plugins/images/tabs/homeassistant.png" "$outdir/homeassistant.png"
convert_file "convert $convert_options" "$global_indir/gitman/organizr/plugins/images/tabs/netdata.png" "$outdir/netdata.png"
convert_file "convert $convert_options" "$global_indir/gitman/organizr/plugins/images/tabs/pihole.png" "$outdir/pihole.png"
convert_file "convert $convert_options" "$global_indir/gitman/organizr/plugins/images/tabs/speedtest-icon.png" "$outdir/speedtest.png"
convert_file "convert $convert_options" "$global_indir/gitman/organizr/plugins/images/tabs/unifi.png" "$outdir/unifi.png"

### Kubernetes Icons ###

outdir="$global_outdir/kubernetes"
mkdir -p "$outdir"

### Other Icons ###

outdir="$global_outdir/other"
mkdir -p "$outdir"

convert_file "convert $convert_options" "$global_indir/other/apple.svg.bin" "$outdir/apple.png"
convert_file "convert $convert_options" "$global_indir/other/homer.png" "$outdir/homer.png"
convert_file "convert $convert_options" "$global_indir/other/odroid.png" "$outdir/odroid.png"
convert_file "convert $convert_options" "$global_indir/other/prometheus.svg.bin" "$outdir/prometheus.png"
convert_file "convert $convert_options" "$global_indir/other/raspberry-pi.svg.bin" "$outdir/raspberry-pi.png"
convert_file "convert $convert_options" "$global_indir/other/smtp4dev.png" "$outdir/smtp4dev.png"
convert_file "convert $convert_options" "$global_indir/other/upc.svg.bin" "$outdir/upc.png"
convert_file "convert $convert_options" "$global_indir/other/uptime-kuma.svg.bin" "$outdir/uptime-kuma.png"
convert_file "convert $convert_options" "$global_indir/other/tp-link.svg.bin" "$outdir/tp-link.png"
convert_file "convert $convert_options" "$global_indir/other/tp-link-omada.svg.bin" "$outdir/tp-link-omada.png"

### Cleanup ###

rm -rf "$tmpdir"
