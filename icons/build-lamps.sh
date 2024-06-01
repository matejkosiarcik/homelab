#!/bin/sh
set -euf

. "$(dirname "$0")/.build-utils.sh"

outdir="$(git rev-parse --show-toplevel)/.shared/lamps/network-server/frontend"

### Favicon ###

# ICO
convert_file "magick INPUT_FILE -resize 16x16 -density 1200 -background none -bordercolor transparent OUTPUT_FILE" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$tmpdir/lamps-16.png"
convert_file "magick INPUT_FILE -resize 32x32 -density 1200 -background none -bordercolor transparent OUTPUT_FILE" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$tmpdir/lamps-32.png"
convert_file "magick INPUT_FILE -resize 48x48 -density 1200 -background none -bordercolor transparent OUTPUT_FILE" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$tmpdir/lamps-48.png"
convert_ico "$tmpdir/lamps-16.png $tmpdir/lamps-32.png $tmpdir/lamps-48.png" "$outdir/favicon.ico"

# PNG
convert_file "magick INPUT_FILE -resize 64x64 -density 1200 -background none -bordercolor transparent -transparent white OUTPUT_FILE" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$outdir/favicon.png"
convert_file "magick INPUT_FILE -resize 180x180 -density 1200 -background none -bordercolor transparent -transparent white OUTPUT_FILE" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$outdir/apple-touch-icon.png"

# WEBP
convert_file "magick INPUT_FILE -resize 64x64 -density 1200 -background none -bordercolor transparent -transparent white OUTPUT_FILE" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$outdir/favicon.webp"

### Cleanup ###

rm -rf "$tmpdir"
