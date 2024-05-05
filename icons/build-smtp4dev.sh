#!/bin/sh
set -euf
# shellcheck disable=SC2248

PATH="$PATH:$(dirname "$0")/node_modules/.bin"

global_indir="$(git rev-parse --show-toplevel)/icons"
global_outdir="$(git rev-parse --show-toplevel)/machines/odroid-h3/smtp4dev/config"
mkdir -p "$global_outdir"

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

### Favicon ###

outdir="$global_outdir"
mkdir -p "$outdir" "$tmpdir/smtp4dev-favicon"

convert_file 'convert -resize 16x16 -density 1200 -background none -bordercolor transparent' "$global_indir/other/smtp4dev - favicon.png" "$tmpdir/smtp4dev-favicon/smtp4dev-16.png"
convert_file 'convert -resize 32x32 -density 1200 -background none -bordercolor transparent' "$global_indir/other/smtp4dev - favicon.png" "$tmpdir/smtp4dev-favicon/smtp4dev-32.png"
png2ico "$outdir/favicon.ico" --colors 16 "$tmpdir/smtp4dev-favicon/smtp4dev-16.png" "$tmpdir/smtp4dev-favicon/smtp4dev-32.png"

rm -rf "$tmpdir/smtp4dev-favicon"

### Cleanup ###

rm -rf "$tmpdir"
