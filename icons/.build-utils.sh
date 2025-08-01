#!/bin/sh
set -euf

PATH="$PATH:$(dirname "$0")/node_modules/.bin"
tmpdir="$(mktemp -d)"
mkdir "$tmpdir/file"
unzip -q 13_05_osa_icons_svg.zip -d "$tmpdir/13_05_osa_icons_svg"

default_image_size='1x1'
default_convert_options='magick INPUT_FILE OUTPUT_FILE'

optimize_image() {
    # $1 - filepath

    # Skip optimization in dev mode
    if [ "${HOMELAB_ENV-x}" = 'dev' ]; then
        return 0
    fi

    tmpdir2="$(mktemp -d)"
    tmpfile2="$tmpdir2/$(basename "$1")"

    if printf '%s' "$(basename "$1")" | grep -E '\.png$' >/dev/null 2>&1; then
        cp "$1" "$tmpfile2"
        oxipng --opt max --strip safe --zopfli --force "$tmpfile2"
        if [ "$(wc -c <"$tmpdir2/$(basename "$1")")" -lt "$(wc -c <"$1")" ]; then
            mv "$tmpfile2" "$1"
        fi
        rm -f "$tmpfile2"

        cp "$1" "$tmpfile2"
        zopflipng --iterations=200 --filters=01234mepb --lossy_8bit --lossy_transparent -y "$tmpfile2" "$tmpfile2"
        if [ "$(wc -c <"$tmpdir2/$(basename "$1")")" -lt "$(wc -c <"$1")" ]; then
            mv "$tmpfile2" "$1"
        fi
        rm -f "$tmpfile2"
    fi

    rm -rf "$tmpdir2"
}

convert_image_draft() {
    # $1 - imagemagick command
    # $2 - input file
    # $3 - output file

    mkdir -p "$(dirname "$3")"
    command="$(printf '%s' "$1" | sed -E "s~INPUT_FILE~'$(printf '%s' "$2" | tr '&' ':')'~g;s~OUTPUT_FILE~'$3'~g;s~RESOLUTION~'$default_image_size'~g" | tr ':' '&')"
    eval "$command"
}

convert_image_full() {
    # $1 - input file
    # $2 - output file

    convert_image_draft "$default_convert_options" "$1" "$2"
    convert_image_draft 'magick INPUT_FILE -background none -bordercolor transparent -gravity center -extent RESOLUTION OUTPUT_FILE' "$2" "$2"
    optimize_image "$2"
}

convert_ico() {
    # $1 - input files
    # $2 - output file

    rm -f "$2"
    # shellcheck disable=SC2086
    png2ico "$2" --colors 16 $1
    # shellcheck disable=SC2086
    rm -f $1
}
