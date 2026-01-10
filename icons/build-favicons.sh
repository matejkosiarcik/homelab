#!/bin/sh
set -euf

mode=''
if [ "${HOMELAB_ENV-}" != '' ]; then
    mode="$HOMELAB_ENV"
fi
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d | --dev)
        mode='dev'
        shift
        ;;
    -p | --prod)
        mode='prod'
        shift
        ;;
    *)
        printf 'Unknown argument %s\n' "$1"
        exit 1
        ;;
    esac
done
HOMELAB_ENV="$mode"

input_dir="$(git rev-parse --show-toplevel)/icons"
output_dir="$(git rev-parse --show-toplevel)/docker-images/custom/favicons/icons"
rm -rf "$output_dir"
mkdir -p "$output_dir"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

# shellcheck disable=SC2034
default_image_size='64x64'
# shellcheck disable=SC2034
default_convert_options='magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize RESOLUTION -density 2000 OUTPUT_FILE'

# Smtp4dev

convert_image_draft 'magick -background none INPUT_FILE -resize 16x16 -density 1200 OUTPUT_FILE' "$input_dir/other/smtp4dev-favicon.png" "$tmpdir/smtp4dev-favicon-16.png"
optimize_image "$tmpdir/smtp4dev-favicon-16.png"
convert_image_draft 'magick -background none INPUT_FILE -resize 32x32 -density 1200 OUTPUT_FILE' "$input_dir/other/smtp4dev-favicon.png" "$tmpdir/smtp4dev-favicon-32.png"
optimize_image "$tmpdir/smtp4dev-favicon-32.png"
convert_ico "$tmpdir/smtp4dev-favicon-16.png $tmpdir/smtp4dev-favicon-32.png" "$(git rev-parse --show-toplevel)/docker-images/external/smtp4dev/icons/favicon.ico"
convert_image_full "$input_dir/other/smtp4dev-favicon.png" "$(git rev-parse --show-toplevel)/docker-images/external/smtp4dev/icons/favicon.png"

## Other ##

convert_image_full "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" "$output_dir/docker-stats.png"
convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ns.svg" "$output_dir/nodeexporter.png"
convert_image_full "$input_dir/other/renovatebot.png" "$output_dir/renovatebot.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/samba-server.svg" "$output_dir/samba.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/unbound.svg" "$output_dir/unbound.png"

## Prebuilds ##

convert_image_full "$input_dir/prebuild/docker-cache.png" "$output_dir/docker-cache.png"
convert_image_full "$input_dir/prebuild/git-cache.png" "$output_dir/git-cache.png"
convert_image_full "$input_dir/prebuild/npm-cache.png" "$output_dir/npm-cache.png"
convert_image_full "$input_dir/prebuild/ollama.png" "$output_dir/ollama.png"
convert_image_full "$input_dir/prebuild/lets-encrypt.png" "$output_dir/certbot.png"

### Cleanup ###

rm -rf "$tmpdir"
