#!/bin/sh
set -euf

. "$(dirname "$0")/.build-utils.sh"
indir="$(git rev-parse --show-toplevel)/icons"
outdir="$(git rev-parse --show-toplevel)/machines/odroid-h3/smtp4dev/config"
mkdir -p "$outdir"

### Favicon ###

convert_file 'magick INPUT_FILE -resize 16x16 -density 1200 -background none -bordercolor transparent OUTPUT_FILE' "$indir/other/smtp4dev - favicon.png" "$tmpdir/favicon-16.png"
convert_file 'magick INPUT_FILE -resize 32x32 -density 1200 -background none -bordercolor transparent OUTPUT_FILE' "$indir/other/smtp4dev - favicon.png" "$tmpdir/favicon-32.png"
png2ico "$outdir/favicon.ico" --colors 16 "$tmpdir/favicon-16.png" "$tmpdir/favicon-32.png"

### Cleanup ###

rm -rf "$tmpdir"
