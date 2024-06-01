#!/bin/sh
set -euf

PATH="$PATH:$(dirname "$0")/node_modules/.bin"
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/file"
unzip -q 13_05_osa_icons_svg.zip -d "$tmpdir/13_05_osa_icons_svg"

convert_image() {
    _infile="$tmpdir/file/$(basename "$2" .bin | tr ' ' '-')"
    cp "$2" "$_infile"
    _outfile="$3"
    rm -f "$_outfile"

    command="$(printf '%s' "$1" | sed -E "s~INPUT_FILE~$_infile~g;s~OUTPUT_FILE~$_outfile~g")"
    $command
    rm -f "$_infile"

    if printf '%s' "$_outfile" | grep -E '\.png$' >/dev/null 2>&1; then
        zopflipng --iterations=200 --filters=01234mepb --lossy_8bit --lossy_transparent -y "$_outfile" "$_outfile"
    fi
}

convert_ico() {
    _infiles="$1"
    _outfile="$2"

    rm -f "$_outfile"
    png2ico "$_outfile" --colors 16 $_infiles
    rm -f $_infiles
}
