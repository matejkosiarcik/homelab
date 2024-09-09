#!/bin/sh
set -euf

PATH="$PATH:$(dirname "$0")/node_modules/.bin"
tmpdir="$(mktemp -d)"
mkdir "$tmpdir/file"
unzip -q 13_05_osa_icons_svg.zip -d "$tmpdir/13_05_osa_icons_svg"

convert_image_draft() {
    _infile="$2"
    if [ "$2" != '' ]; then
        _infile="$tmpdir/file/$(basename "$2" .bin | tr ' ' '-')"
        cp "$2" "$_infile"
    fi
    _outfile="$3"
    rm -f "$_outfile"
    mkdir -p "$(dirname "$_outfile")"

    command="$(printf '%s' "$1" | sed -E "s~INPUT_FILE~$_infile~g;s~OUTPUT_FILE~$_outfile~g")"
    $command
    rm -f "$_infile"
}

convert_image() {
    # $1 - convert command
    # $2 - input file
    # $3 - output file
    convert_image_draft "$1" "$2" "$3"

    if printf '%s' "$3" | grep -E '\.png$' >/dev/null 2>&1; then
        zopflipng --iterations=100 --filters=01234mepb --lossy_8bit --lossy_transparent -y "$3" "$3"
    fi
}

convert_ico() {
    _infiles="$1"
    _outfile="$2"

    rm -f "$_outfile"
    # shellcheck disable=SC2086
    png2ico "$_outfile" --colors 16 $_infiles
    # shellcheck disable=SC2086
    rm -f $_infiles
}
