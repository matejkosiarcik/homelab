#!/bin/sh
set -euf
# shellcheck disable=SC2248

PATH="$PATH:$(dirname "$0")/node_modules/.bin"

global_indir="$(git rev-parse --show-toplevel)/icons"
global_outdir="$(git rev-parse --show-toplevel)/machines/odroid-h3/homer/config/assets/icons"
rm -rf "$global_outdir"
mkdir "$global_outdir"

convert_options='-resize 128x128 -density 1200 -background none -bordercolor transparent -border 1'
tmpdir="$(mktemp -d)"
convert_file () {
    command="$1"
    _infile="$tmpdir/$(basename "$2" .bin)"
    cp "$2" "$_infile"
    _outfile="$3"
    $command "$_infile" "$_outfile"
    rm -f "$_infile"
    zopflipng --iterations=200 --filters=01234mepb --lossy_8bit --lossy_transparent -y "$_outfile" "$_outfile"
}

### Other Icons ###

outdir="$global_outdir/other"
mkdir "$outdir"

# Raspberry Pi

infile="$global_indir/other/raspberry-pi.svg.bin"
outfile="$outdir/raspberry-pi.png"
convert_file "convert $convert_options" "$infile" "$outfile"

### Cleanup ###

rm -rf "$tmpdir"
