#!/bin/sh
set -euf
# shellcheck disable=SC2248

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
output_dir="$(git rev-parse --show-toplevel)/icons/prebuild"
rm -rf "$output_dir"
mkdir -p "$output_dir"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

# shellcheck disable=SC2034
default_image_size='512x512'
# shellcheck disable=SC2034
default_convert_options='magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize RESOLUTION -density 2000 OUTPUT_FILE'

### Simple icons ###

# Cache
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/pvc.svg" -resize "1000x1000" -border 50 "$tmpdir/cache.png"
convert_image_full "$tmpdir/cache.png" "$output_dir/cache.png"

# Cloud
magick -density 2000 -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_cloud.svg" -resize "1000x1000" -border 20 "$tmpdir/cloud.png"
convert_image_full "$tmpdir/cloud.png" "$output_dir/cloud.png"

### Composite icons ###

# Git remote registry
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/git.svg" -resize "500x500" "$tmpdir/git.png"
magick "$tmpdir/cache.png" "$tmpdir/git.png" -gravity Center -geometry "+275+275" -composite "$tmpdir/git-cache.png"
convert_image_full "$tmpdir/git-cache.png" "$output_dir/git-cache.png"

# NPM remote registry
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/npm.svg" -resize "750x750" "$tmpdir/npm.png"
magick "$tmpdir/cache.png" "$tmpdir/npm.png" -gravity Center -geometry "+150+400" -composite "$tmpdir/npm-cache.png"
convert_image_full "$tmpdir/npm-cache.png" "$output_dir/npm-cache.png"

# APT remote registry
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/debian-linux.svg" -resize "400x400" "$tmpdir/debian.png"
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/ubuntu-linux.svg" -resize "400x400" "$tmpdir/ubuntu.png"
magick "$tmpdir/cloud.png" "$tmpdir/ubuntu.png" -gravity Center -geometry "+250+175" -composite "$tmpdir/debian.png" -gravity Center -geometry "-150+175" -composite "$tmpdir/apt-cloud.png"
convert_image_full "$tmpdir/apt-cloud.png" "$output_dir/apt-cloud.png"

# Git remote registry
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/git.svg" -resize "500x500" "$tmpdir/git.png"
magick "$tmpdir/cloud.png" "$tmpdir/git.png" -gravity Center -geometry "+200+200" -composite "$tmpdir/git-cloud.png"
convert_image_full "$tmpdir/git-cloud.png" "$output_dir/git-cloud.png"

# Docker remote registry
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" -resize "600x600" "$tmpdir/docker.png"
magick "$tmpdir/cloud.png" "$tmpdir/docker.png" -gravity Center -geometry "+200+200" -composite "$tmpdir/docker-cloud.png"
convert_image_full "$tmpdir/docker-cloud.png" "$output_dir/docker-cloud.png"

# NPM remote registry
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/npm.svg" -resize "750x750" "$tmpdir/npm.png"
magick "$tmpdir/cloud.png" "$tmpdir/npm.png" -gravity Center -geometry "+100+200" -composite "$tmpdir/npm-cloud.png"
convert_image_full "$tmpdir/npm-cloud.png" "$output_dir/npm-cloud.png"

# PyPi remote registry
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/python.svg" -resize "550x550" "$tmpdir/python.png"
magick "$tmpdir/cloud.png" "$tmpdir/python.png" -gravity Center -geometry "+200+200" -composite "$tmpdir/pypi-cloud.png"
convert_image_full "$tmpdir/pypi-cloud.png" "$output_dir/pypi-cloud.png"

# RubyGems remote registry
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/ruby.svg" -resize "400x400" "$tmpdir/ruby.png"
magick "$tmpdir/cloud.png" "$tmpdir/ruby.png" -gravity Center -geometry "+275+150" -composite "$tmpdir/rubygems-cloud.png"
convert_image_full "$tmpdir/rubygems-cloud.png" "$output_dir/rubygems-cloud.png"

### Cleanup ###

rm -rf "$tmpdir"
