#!/bin/sh
set -euf

PATH="$PATH:$(dirname "$0")/node_modules/.bin"
tmpdir="$(mktemp -d)"
mkdir "$tmpdir/file"
unzip -q 13_05_osa_icons_svg.zip -d "$tmpdir/13_05_osa_icons_svg"

default_image_size='1x1'
default_convert_options='magick INPUT_FILE OUTPUT_FILE'

# Check if an icon should be generated based on the --only filter
should_generate_icon() {
    if [ -z "${only_pattern:-}" ]; then
        return 0  # Generate everything if no filter is set
    fi

    printf '%s\n' "${1}" | tr '/' '\n' | while read -r filepart; do
        if printf '%s\n' "$filepart" | grep -qE ".*(?:${only_pattern}).*" >/dev/null; then
            return 0
        fi
    done

    return 1;
}

optimize_image() {
    # $1 - filepath
    if ! should_generate_icon "$1"; then
        return 0
    fi

    # Skip optimization in dev mode
    if [ "${HOMELAB_ENV-x}" = 'dev' ]; then
        return 0
    fi

    tmpdir2="$(mktemp -d)"
    tmpfile2="$tmpdir2/$(basename "$1")"

    if printf '%s' "$(basename "$1")" | grep -E '\.png$' >/dev/null 2>&1; then
        cp "$1" "$tmpfile2"
        oxipng --opt max --strip safe --force "$tmpfile2"
        if [ "$(wc -c <"$tmpdir2/$(basename "$1")")" -lt "$(wc -c <"$1")" ]; then
            mv "$tmpfile2" "$1"
        fi
        rm -f "$tmpfile2"

        cp "$1" "$tmpfile2"
        zopflipng --iterations=20 --filters=01234mepb --lossy_8bit --lossy_transparent -y "$tmpfile2" "$tmpfile2"
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

    if ! should_generate_icon "$3"; then
        return 0
    fi

    mkdir -p "$(dirname "$3")"
    command="$(printf '%s' "$1" | sed -E "s~INPUT_FILE~'$(printf '%s' "$2" | tr '&' ':')'~g;s~OUTPUT_FILE~'$3'~g;s~RESOLUTION~'$default_image_size'~g" | tr ':' '&')"
    eval "$command"
}

convert_image_draft_2() {
    # $1 - imagemagick command
    # $2 - input file 1
    # $3 - input file 2
    # $4 - output file

    if ! should_generate_icon "$4"; then
        return 0
    fi

    mkdir -p "$(dirname "$4")"
    command="$(printf '%s' "$1" | sed -E "s~INPUT_FILE1~'$(printf '%s' "$2" | tr '&' ':')'~g;s~INPUT_FILE2~'$(printf '%s' "$3" | tr '&' ':')'~g;s~OUTPUT_FILE~'$4'~g;s~RESOLUTION~'$default_image_size'~g" | tr ':' '&')"
    eval "$command"
}

convert_image_draft_3() {
    # $1 - imagemagick command
    # $2 - input file 1
    # $3 - input file 2
    # $4 - input file 3
    # $5 - output file

    if ! should_generate_icon "$5"; then
        return 0
    fi

    mkdir -p "$(dirname "$5")"
    command="$(printf '%s' "$1" | sed -E "s~INPUT_FILE1~'$(printf '%s' "$2" | tr '&' ':')'~g;s~INPUT_FILE2~'$(printf '%s' "$3" | tr '&' ':')'~g;s~INPUT_FILE3~'$(printf '%s' "$4" | tr '&' ':')'~g;s~OUTPUT_FILE~'$5'~g;s~RESOLUTION~'$default_image_size'~g" | tr ':' '&')"
    eval "$command"
}

convert_image_full() {
    # $1 - input file
    # $2 - output file

    if ! should_generate_icon "$2"; then
        return 0
    fi

    mkdir -p "$(dirname "$2")"
    convert_image_draft "$default_convert_options" "$1" "$2"
    convert_image_draft 'magick INPUT_FILE -background none -bordercolor transparent -gravity center -extent RESOLUTION OUTPUT_FILE' "$2" "$2"
    optimize_image "$2"
}

convert_ico() {
    # $1 - input files
    # $2 - output file

    if ! should_generate_icon "$2"; then
        return 0
    fi

    mkdir -p "$(dirname "$2")"
    rm -f "$2"
    # shellcheck disable=SC2086
    png2ico "$2" --colors 16 $1
}
