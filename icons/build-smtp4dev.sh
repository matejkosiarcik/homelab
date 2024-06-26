#!/bin/sh
set -euf

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

indir="$(git rev-parse --show-toplevel)/icons"
outdir="$(git rev-parse --show-toplevel)/components/smtp4dev"
mkdir -p "$outdir"

### Favicon ###

convert_image 'magick INPUT_FILE -resize 16x16 -density 1200 -background none -bordercolor transparent OUTPUT_FILE' "$indir/other/smtp4dev - favicon.png" "$tmpdir/favicon-16.png"
convert_image 'magick INPUT_FILE -resize 32x32 -density 1200 -background none -bordercolor transparent OUTPUT_FILE' "$indir/other/smtp4dev - favicon.png" "$tmpdir/favicon-32.png"
convert_ico "$tmpdir/favicon-16.png $tmpdir/favicon-32.png" "$outdir/favicon.ico"

### Cleanup ###

rm -rf "$tmpdir"
