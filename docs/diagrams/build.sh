#!/bin/sh
set -euf

if [ "$#" -lt 1 ]; then
    only_diagram=''
else
    only_diagram="$1"
fi

diagrams_dir="$(dirname "$0")"

build_diagram() {
    # $1 - diagram name
    mkdir -p "$(dirname "$diagrams_dir/out/$1")"
    mmdc --scale 2 --input "$diagrams_dir/src/$1.mmd" --output "$diagrams_dir/out/$1.png" --cssFile "$diagrams_dir/style.css"
}

if [ "$only_diagram" = '' ]; then
    find src -name '*.mmd' | while read -r file; do
        diagram="$(printf '%s' "$file" | sed -E 's~^[^/]+/~~;s~\.mmd$~~')"
        build_diagram "$diagram"
    done
else
    build_diagram "$only_diagram"
fi
