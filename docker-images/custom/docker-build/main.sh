#!/bin/sh
set -euf

cd /homelab/docker-images
find . -type d -mindepth 1 -maxdepth 2 | while read -r dir; do
    if [ -f "$dir/Dockerfile" ]; then
        docker build . --pull --file "$dir/Dockerfile" -t "homelab/$(basename "$dir"):nightly-amd64" --platform 'linux/amd64'
        docker build . --pull --file "$dir/Dockerfile" -t "homelab/$(basename "$dir"):nightly-arm64" --platform 'linux/arm64/v8'
    fi
done
