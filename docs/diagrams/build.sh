#!/bin/sh
set -euf

if [ "$#" -lt 1 ]; then
    only_diagram='';
else
    only_diagram="$1"
fi

build_diagram() {
    # $1 - diagram name
    mkdir -p "$(dirname "out/$1")"
    mmdc --scale 2 --input "src/$1.mmd" --output "out/$1.png"
}

if [ "$only_diagram" = '' ]; then
    find src -name '*.mmd' | while read -r file; do
        diagram="$(printf '%s' "$file" | sed -E 's~^[^/]+/~~;s~\.mmd$~~')"
        build_diagram "$diagram"
    done
else
    build_diagram "$only_diagram"
fi
