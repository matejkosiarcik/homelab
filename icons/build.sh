#!/bin/sh
set -euf
# shellcheck disable=SC2248

PATH="$PATH:$(dirname "$0")/node_modules/.bin"

global_indir="$(git rev-parse --show-toplevel)/icons"
global_outdir="$(git rev-parse --show-toplevel)/machines/odroid-h3/homer/config/assets/icons"
rm -rf "$global_outdir"
mkdir "$global_outdir"

# NOTE: 126px is because the border adds 1px on each side -> so the result dimension is 128px
convert_options='-resize 126x126 -density 1200 -background none -bordercolor transparent -border 1'
tmpdir="$(mktemp -d)"
mkdir "$tmpdir/file"

convert_file () {
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
mkdir "$outdir"
unzip -q 13_05_osa_icons_svg.zip -d "$tmpdir/13_05_osa_icons_svg"

convert_file "convert $convert_options" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$outdir/awareness.png"

rm -rf "$tmpdir/13_05_osa_icons_svg"

### Other Icons ###

outdir="$global_outdir/other"
mkdir "$outdir"

convert_file "convert $convert_options" "$global_indir/other/raspberry-pi.svg.bin" "$outdir/raspberry-pi.png"

### Cleanup ###

rm -rf "$tmpdir"
