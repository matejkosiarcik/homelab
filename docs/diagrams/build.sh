#!/bin/sh
set -euf

if [ "$#" -lt 1 ]; then
    only_diagram=''
else
    only_diagram="$1"
fi

diagrams_dir="$(dirname "$0")"

alias drawio='/Applications/draw.io.app/Contents/MacOS/draw.io'

build_diagram() {
    # $1 - diagram name
    mkdir -p "$(dirname "$diagrams_dir/out/$1")"
    extension="$(printf '%s' "$1" | sed -E 's~^.+\.~~')"
    output_file="$(printf '%s' "$1" | sed -E 's~src/~~;s~\.[^.]+$~.png~')"

    if [ "$extension" = 'mmd' ]; then
        mmdc --scale 2 --input "$diagrams_dir/$1" --output "$diagrams_dir/out/$output_file" --cssFile "$diagrams_dir/style.css"
    elif [ "$extension" = 'ts' ]; then
        tsx "$diagrams_dir/$1"
        drawio -x -f png --scale 2 --border 100 -o "$diagrams_dir/out/$output_file"  "$diagrams_dir/$(printf '%s' "$1" | sed -E 's~\.ts$~~').drawio"
    elif [ "$extension" = 'drawio' ]; then
        drawio -x -f png --scale 2 --border 100 -o "$diagrams_dir/out/$output_file"  "$diagrams_dir/$1"
    fi
}

if [ "$only_diagram" = '' ]; then
    find src -name '*.mmd' | while read -r file; do
        build_diagram "$file"
    done
    find src -name '*.ts' -maxdepth 1 | while read -r file; do
        build_diagram "$file"
    done
else
    build_diagram "$only_diagram"
fi
