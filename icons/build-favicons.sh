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
default_convert_options='magick -background none -bordercolor transparent INPUT_FILE -resize RESOLUTION -density 1200 OUTPUT_FILE'

### Custom Certbot ###
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/lets-encrypt-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/lets-encrypt-background-mask.png"
magick "$tmpdir/lets-encrypt-background.png" "$tmpdir/lets-encrypt-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/lets-encrypt-background.png"
magick "$tmpdir/lets-encrypt-background.png" -define png:color-type=6 "$tmpdir/lets-encrypt-background.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/lets-encrypt.svg" -resize '48x48' -density 1200 "$tmpdir/lets-encrypt-tmp.png"
magick "$tmpdir/lets-encrypt-background.png" "$tmpdir/lets-encrypt-tmp.png" -gravity Center -composite "$tmpdir/lets-encrypt-final.png"
convert_image_full "$tmpdir/lets-encrypt-final.png" "$output_dir/certbot.png"

## Custom Ollama ##
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/ollama-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/ollama-background-mask.png"
magick "$tmpdir/ollama-background.png" "$tmpdir/ollama-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/ollama-background.png"
magick "$tmpdir/ollama-background.png" -define png:color-type=6 "$tmpdir/ollama-background.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/ollama.svg" -resize '48x48' -density 1200 "$tmpdir/ollama-tmp.png"
magick "$tmpdir/ollama-background.png" "$tmpdir/ollama-tmp.png" -gravity Center -composite "$tmpdir/ollama-final.png"
convert_image_full "$tmpdir/ollama-final.png" "$output_dir/ollama.png"

# Smtp4dev

convert_image_draft 'magick -background none INPUT_FILE -resize 16x16 -density 1200 OUTPUT_FILE' "$input_dir/other/smtp4dev-favicon.png" "$tmpdir/smtp4dev-favicon-16.png"
optimize_image "$tmpdir/smtp4dev-favicon-16.png"
convert_image_draft 'magick -background none INPUT_FILE -resize 32x32 -density 1200 OUTPUT_FILE' "$input_dir/other/smtp4dev-favicon.png" "$tmpdir/smtp4dev-favicon-32.png"
optimize_image "$tmpdir/smtp4dev-favicon-32.png"
convert_ico "$tmpdir/smtp4dev-favicon-16.png $tmpdir/smtp4dev-favicon-32.png" "$(git rev-parse --show-toplevel)/docker-images/external/smtp4dev/icons/favicon.ico"

convert_image_full "$input_dir/other/smtp4dev-favicon.png" "$(git rev-parse --show-toplevel)/docker-images/external/smtp4dev/icons/favicon.png"

## Other ##

convert_image_full "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" "$tmpdir/docker.png"
cp "$tmpdir/docker.png" "$output_dir/docker-cache-proxy.png"
cp "$tmpdir/docker.png" "$output_dir/docker-stats.png"

convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ns.svg" "$output_dir/nodeexporter.png"
convert_image_full "$input_dir/other/renovatebot.png" "$output_dir/renovatebot.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/samba-server.svg" "$output_dir/samba.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/unbound.svg" "$output_dir/unbound.png"

### Cleanup ###

rm -rf "$tmpdir"
