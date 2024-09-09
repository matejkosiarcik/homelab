#!/bin/sh
set -euf

if [ "$#" -lt 1 ]; then
    only_diagram='';
else
    only_diagram="$1"
fi

build_diagram() {
    # $1 - diagram name
    mmdc --scale 2 --input "src/$1.mmd" --output "out/$1.png"
}

if [ "$only_diagram" = '' ]; then
    find src -name '*.mmd' -print0 | xargs -0 -n1 sh -c 'basename "$1" .mmd' - | while read -r diagram; do
        build_diagram "$diagram"
    done
else
    build_diagram "$only_diagram"
fi
