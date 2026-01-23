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

# Prometheus
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" -resize '1000x1000' -border 50 "$tmpdir/prometheus-background.png"
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" -resize '1000x1000' -border 20 "$tmpdir/prometheus-alone.png"
convert_image_full "$tmpdir/prometheus-alone.png" "$output_dir/prometheus.png"

# Rounded Squid
magick "$input_dir/other/squid.jpg" \( +clone -alpha extract -draw "fill black roundrectangle 0,0 %[w],%[h] 12,12" -negate \) -alpha off -compose CopyOpacity -composite "$tmpdir/squid.png"
convert_image_full "$tmpdir/squid.png" "$output_dir/squid.png"

### Combined icons ###

# Servers
magick -density 2000 -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_server.svg" -resize '1000x1000' -border 10 -density 2000 "$tmpdir/server-1.png"
magick -density 2000 -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_server.svg" -resize '650x650' -density 2000 "$tmpdir/server-2.png"
magick -density 2000 -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_server.svg" -resize '550x550' -density 2000 "$tmpdir/server-3.png"
magick "$tmpdir/server-1.png" "$tmpdir/server-2.png" -gravity Center -geometry '-200+175' -composite -resize '1000x1000' "$tmpdir/servers.png"
magick "$tmpdir/servers.png" "$tmpdir/server-3.png" -gravity Center -geometry '+200+225' -composite -resize '1000x1000' "$tmpdir/servers.png"
convert_image_full "$tmpdir/servers.png" "$output_dir/servers.png"

# Personal devices
magick -density 2000 -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_laptop.svg" -resize '1000x1000' -border 10 -density 2000 "$tmpdir/laptop.png"
magick -density 2000 -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_iPhone.svg" -resize '800x800' -density 2000 "$tmpdir/phone.png"
magick "$tmpdir/laptop.png" "$tmpdir/phone.png" -gravity Center -geometry '+275+100' -composite -resize '1000x1000' "$tmpdir/personal-devices.png"
convert_image_full "$tmpdir/personal-devices.png" "$output_dir/personal-devices.png"

### Icons with background ###

magick -size '1000x1000' xc:#ffffffef "$tmpdir/white-background.png"
magick -size '1000x1000' xc:black -fill white -draw "roundRectangle 0,0,1000,1000 80,80" "$tmpdir/white-background-mask.png"
magick "$tmpdir/white-background.png" "$tmpdir/white-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/white-background.png"
magick "$tmpdir/white-background.png" -define png:color-type=6 "$tmpdir/white-background.png"

# DWService with custom background
magick -density 2000 -background none -bordercolor transparent "$input_dir/other/dwservice.png" -resize '900x900' -density 2000 "$tmpdir/dwservice-foreground.png"
magick "$tmpdir/white-background.png" "$tmpdir/dwservice-foreground.png" -gravity Center -composite "$tmpdir/dwservice.png"
convert_image_full "$tmpdir/dwservice.png" "$output_dir/dwservice.png"

# Let's Encrypt
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/lets-encrypt.svg" -resize '900x900' -density 2000 "$tmpdir/lets-encrypt-foreground.png"
magick "$tmpdir/white-background.png" "$tmpdir/lets-encrypt-foreground.png" -gravity Center -geometry '+0+0' -composite "$tmpdir/lets-encrypt.png"
convert_image_full "$tmpdir/lets-encrypt.png" "$output_dir/lets-encrypt.png"

# LibreTranslate
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/libretranslate.svg" -resize '850x850' -density 2000 "$tmpdir/libretranslate-foreground.png"
magick "$tmpdir/white-background.png" "$tmpdir/libretranslate-foreground.png" -gravity Center -geometry '+0+0' -composite "$tmpdir/libretranslate.png"
convert_image_full "$tmpdir/libretranslate.png" "$output_dir/libretranslate.png"

# Ollama
magick -density 2000 -background none -bordercolor transparent "$input_dir/other/openwebui.png" -resize '1000x1000' -density 2000 "$tmpdir/openwebui-foreground.png"
magick "$tmpdir/white-background.png" "$tmpdir/openwebui-foreground.png" -gravity Center -geometry '+0+0' -composite "$tmpdir/openwebui.png"
convert_image_full "$tmpdir/openwebui.png" "$output_dir/openwebui.png"

# Open WebUI
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/ollama.svg" -resize '850x850' -density 2000 "$tmpdir/ollama-foreground.png"
magick "$tmpdir/white-background.png" "$tmpdir/ollama-foreground.png" -gravity Center -geometry '+0+0' -composite "$tmpdir/ollama.png"
convert_image_full "$tmpdir/ollama.png" "$output_dir/ollama.png"

# Smtp4dev with custom background
magick -density 2000 -background none -bordercolor transparent "$input_dir/other/smtp4dev-custom.png" -resize '875x875' -density 2000 "$tmpdir/smtp4dev-foreground.png"
magick "$tmpdir/white-background.png" "$tmpdir/smtp4dev-foreground.png" -gravity Center -composite "$tmpdir/smtp4dev.png"
convert_image_full "$tmpdir/smtp4dev.png" "$output_dir/smtp4dev.png"

### Cache ###

# APT cache proxy
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/debian-linux.svg" -resize "450x450" "$tmpdir/debian.png"
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/ubuntu-linux.svg" -resize "450x450" "$tmpdir/ubuntu.png"
magick "$tmpdir/cache.png" "$tmpdir/ubuntu.png" -gravity Center -geometry "+225+300" -composite "$tmpdir/debian.png" -gravity Center -geometry "-225+300" -composite "$tmpdir/apt-cache.png"
convert_image_full "$tmpdir/apt-cache.png" "$output_dir/apt-cache.png"

# Docker cache proxy
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" -resize "700x700" "$tmpdir/docker.png"
magick "$tmpdir/cache.png" "$tmpdir/docker.png" -gravity Center -geometry "+175+275" -composite "$tmpdir/docker-cache.png"
convert_image_full "$tmpdir/docker-cache.png" "$output_dir/docker-cache.png"

# Git cache proxy
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/git.svg" -resize "500x500" "$tmpdir/git.png"
magick "$tmpdir/cache.png" "$tmpdir/git.png" -gravity Center -geometry "+275+275" -composite "$tmpdir/git-cache.png"
convert_image_full "$tmpdir/git-cache.png" "$output_dir/git-cache.png"

# NPM cache proxy
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/npm.svg" -resize "750x750" "$tmpdir/npm.png"
magick "$tmpdir/cache.png" "$tmpdir/npm.png" -gravity Center -geometry "+150+400" -composite "$tmpdir/npm-cache.png"
convert_image_full "$tmpdir/npm-cache.png" "$output_dir/npm-cache.png"

# PyPi cache proxy
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/python.svg" -resize "600x600" "$tmpdir/python.png"
magick "$tmpdir/cache.png" "$tmpdir/python.png" -gravity Center -geometry "+225+225" -composite "$tmpdir/pypi-cache.png"
convert_image_full "$tmpdir/pypi-cache.png" "$output_dir/pypi-cache.png"

# RubyGems cache proxy
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/ruby.svg" -resize "500x500" "$tmpdir/ruby.png"
magick "$tmpdir/cache.png" "$tmpdir/ruby.png" -gravity Center -geometry "+275+300" -composite "$tmpdir/rubygems-cache.png"
convert_image_full "$tmpdir/rubygems-cache.png" "$output_dir/rubygems-cache.png"

### Cloud ###

# APT remote registry
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/debian-linux.svg" -resize "400x400" "$tmpdir/debian.png"
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/ubuntu-linux.svg" -resize "400x400" "$tmpdir/ubuntu.png"
magick "$tmpdir/cloud.png" "$tmpdir/ubuntu.png" -gravity Center -geometry "+250+175" -composite "$tmpdir/debian.png" -gravity Center -geometry "-150+175" -composite "$tmpdir/apt-cloud.png"
convert_image_full "$tmpdir/apt-cloud.png" "$output_dir/apt-cloud.png"

# Docker remote registry
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" -resize "600x600" "$tmpdir/docker.png"
magick "$tmpdir/cloud.png" "$tmpdir/docker.png" -gravity Center -geometry "+200+200" -composite "$tmpdir/docker-cloud.png"
convert_image_full "$tmpdir/docker-cloud.png" "$output_dir/docker-cloud.png"

# Git remote registry
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/git.svg" -resize "500x500" "$tmpdir/git.png"
magick "$tmpdir/cloud.png" "$tmpdir/git.png" -gravity Center -geometry "+200+200" -composite "$tmpdir/git-cloud.png"
convert_image_full "$tmpdir/git-cloud.png" "$output_dir/git-cloud.png"

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

## Prometheus exporters

# Apache prometheus exporter
cp "$input_dir/other/apache.svg.bin" "$tmpdir/apache.svg"
magick -density 2000 -background none -bordercolor transparent "$tmpdir/apache.svg" -resize '800x800' "$tmpdir/apache.png"
magick "$tmpdir/prometheus-background.png" "$tmpdir/apache.png" -gravity Center -geometry '+325+150' -composite "$tmpdir/apache-prometheus-exporter.png"
convert_image_full "$tmpdir/apache-prometheus-exporter.png" "$output_dir/apache-prometheus-exporter.png"

# PiHole prometheus exporter
magick -density 2000 -background none -bordercolor transparent "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" -resize '600x600' "$tmpdir/pihole.png"
magick "$tmpdir/prometheus-background.png" "$tmpdir/pihole.png" -gravity Center -geometry '+325+225' -composite "$tmpdir/pihole-prometheus-exporter.png"
convert_image_full "$tmpdir/pihole-prometheus-exporter.png" "$output_dir/pihole-prometheus-exporter.png"

# Squid prometheus exporter
magick -density 2000 -background none -bordercolor transparent "$output_dir/squid.png" -resize '425x425' "$tmpdir/squid.png"
magick "$tmpdir/prometheus-background.png" "$tmpdir/squid.png" -gravity Center -geometry '+300+300' -composite "$tmpdir/squid-prometheus-exporter.png"
convert_image_full "$tmpdir/squid-prometheus-exporter.png" "$output_dir/squid-prometheus-exporter.png"

### Cleanup ###

rm -rf "$tmpdir"
