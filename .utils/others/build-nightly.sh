#!/bin/sh
set -euf

cd "$(git rev-parse --show-toplevel 2>/dev/null)/docker-images"

find . -type d -mindepth 2 -maxdepth 2 | while read -r dir; do
    if [ ! -f "$dir/Dockerfile" ]; then
        continue
    fi
    docker_image_name="$(printf '%s' "$dir" | sed -E 's~^./~~;s~/~--~g')"
    echo "$dir - $docker_image_name"
    docker build . --file "$dir/Dockerfile" --tag "$docker_image_name:nightly"
done
