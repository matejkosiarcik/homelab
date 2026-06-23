#!/bin/sh
set -euf
# shellcheck disable=SC2248

mode=''
only_pattern=''
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
    --only)
        only_pattern="$2"
        shift 2
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
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "1000x1000" -border 50 OUTPUT_FILE' "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/pvc.svg" "$tmpdir/cache.png"
convert_image_full "$tmpdir/cache.png" "$output_dir/cache.png"
rm -f "$tmpdir/cache.png"

# Cloud
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "1000x1000" -border 20 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_cloud.svg" "$tmpdir/cloud.png"
convert_image_full "$tmpdir/cloud.png" "$output_dir/cloud.png"
rm -f "$tmpdir/cloud.png"

# Prometheus
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "1000x1000" -border 50 OUTPUT_FILE' "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" "$tmpdir/prometheus-background.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "1000x1000" -border 20 OUTPUT_FILE' "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" "$tmpdir/prometheus-alone.png"
convert_image_full "$tmpdir/prometheus-alone.png" "$output_dir/prometheus.png"
rm -f "$tmpdir/prometheus-background.png" "$tmpdir/prometheus-alone.png"

# Rounded Squid
convert_image_draft 'magick INPUT_FILE \( +clone -alpha extract -draw "fill black roundrectangle 0,0 %[w],%[h] 12,12" -negate \) -alpha off -compose CopyOpacity -composite OUTPUT_FILE' "$input_dir/other/squid.jpg" "$tmpdir/squid.png"
convert_image_full "$tmpdir/squid.png" "$output_dir/squid.png"
rm -f "$tmpdir/squid.png"

### Combined icons ###

# Servers
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "1000x1000" -border 10 -density 2000 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_server.svg" "$tmpdir/servers-1.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "650x650" -density 2000 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_server.svg" "$tmpdir/servers-2.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "550x550" -density 2000 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_server.svg" "$tmpdir/servers-3.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "-200+175" -composite -resize "1000x1000" OUTPUT_FILE' "$tmpdir/servers-1.png" "$tmpdir/servers-2.png" "$tmpdir/servers-4.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+200+225" -composite -resize "1000x1000" OUTPUT_FILE' "$tmpdir/servers-4.png" "$tmpdir/servers-3.png" "$tmpdir/servers-5.png"
convert_image_full "$tmpdir/servers-5.png" "$output_dir/servers.png"
rm -f "$tmpdir/servers-1.png" "$tmpdir/servers-2.png" "$tmpdir/servers-3.png" "$tmpdir/servers-4.png" "$tmpdir/servers-5.png"

# Personal devices
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "1000x1000" -border 10 -density 2000 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_laptop.svg" "$tmpdir/laptop.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "800x800" -density 2000 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_iPhone.svg" "$tmpdir/phone.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+275+100" -composite -resize "1000x1000" OUTPUT_FILE' "$tmpdir/laptop.png" "$tmpdir/phone.png" "$tmpdir/personal-devices.png"
convert_image_full "$tmpdir/personal-devices.png" "$output_dir/personal-devices.png"
rm -f "$tmpdir/personal-devices.png"

### Icons with background ###

magick -size '1000x1000' xc:#ffffffef "$tmpdir/white-background.png"
magick -size '1000x1000' xc:black -fill white -draw "roundRectangle 0,0,1000,1000 80,80" "$tmpdir/white-background-mask.png"
magick "$tmpdir/white-background.png" "$tmpdir/white-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/white-background.png"
magick "$tmpdir/white-background.png" -define png:color-type=6 "$tmpdir/white-background.png"

# DWService with custom background
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize '900x900' -density 2000 OUTPUT_FILE' "$input_dir/other/dwservice.png" "$tmpdir/dwservice-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -composite OUTPUT_FILE' "$tmpdir/white-background.png" "$tmpdir/dwservice-foreground.png" "$tmpdir/dwservice.png"
convert_image_full "$tmpdir/dwservice.png" "$output_dir/dwservice.png"
rm -f "$tmpdir/dwservice-foreground.png" "$tmpdir/dwservice.png"

# Let's Encrypt
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize '900x900' -density 2000 OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/lets-encrypt.svg" "$tmpdir/lets-encrypt-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry '+0+0' -composite OUTPUT_FILE' "$tmpdir/white-background.png" "$tmpdir/lets-encrypt-foreground.png" "$tmpdir/lets-encrypt.png"
convert_image_full "$tmpdir/lets-encrypt.png" "$output_dir/lets-encrypt.png"
rm -f "$tmpdir/lets-encrypt-foreground.png" "$tmpdir/lets-encrypt.png"

# LibreTranslate
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize '850x850' -density 2000 OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/libretranslate.svg" "$tmpdir/libretranslate-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry '+0+0' -composite OUTPUT_FILE' "$tmpdir/white-background.png" "$tmpdir/libretranslate-foreground.png" "$tmpdir/libretranslate.png"
convert_image_full "$tmpdir/libretranslate.png" "$output_dir/libretranslate.png"
rm -f "$tmpdir/libretranslate-foreground.png" "$tmpdir/libretranslate.png"

# Ollama
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize '1000x1000' -density 2000 OUTPUT_FILE' "$input_dir/other/openwebui.png" "$tmpdir/openwebui-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry '+0+0' -composite OUTPUT_FILE' "$tmpdir/white-background.png" "$tmpdir/openwebui-foreground.png" "$tmpdir/openwebui.png"
convert_image_full "$tmpdir/openwebui.png" "$output_dir/openwebui.png"
rm -f "$tmpdir/openwebui-foreground.png" "$tmpdir/openwebui.png"

# Open WebUI
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize '850x850' -density 2000 OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/ollama.svg" "$tmpdir/ollama-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry '+0+0' -composite OUTPUT_FILE' "$tmpdir/white-background.png" "$tmpdir/ollama-foreground.png" "$tmpdir/ollama.png"
convert_image_full "$tmpdir/ollama.png" "$output_dir/ollama.png"
rm -f "$tmpdir/ollama-foreground.png" "$tmpdir/ollama.png"

# Smtp4dev with custom background
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize '875x875' -density 2000 OUTPUT_FILE' "$input_dir/other/smtp4dev-custom.png" "$tmpdir/smtp4dev-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry '+0+0' -composite OUTPUT_FILE' "$tmpdir/white-background.png" "$tmpdir/smtp4dev-foreground.png" "$tmpdir/smtp4dev.png"
convert_image_full "$tmpdir/smtp4dev.png" "$output_dir/smtp4dev.png"
rm -f "$tmpdir/smtp4dev-foreground.png" "$tmpdir/smtp4dev.png"

### Cache ###

# APT cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "450x450" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/debian-linux.svg" "$tmpdir/debian.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "450x450" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/ubuntu-linux.svg" "$tmpdir/ubuntu.png"
convert_image_draft_3 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+225+300" -composite INPUT_FILE3 -gravity Center -geometry "-225+300" -composite OUTPUT_FILE' "$tmpdir/cache.png" "$tmpdir/ubuntu.png" "$tmpdir/debian.png" "$tmpdir/apt-cache.png"
convert_image_full "$tmpdir/apt-cache.png" "$output_dir/apt-cache.png"
rm -f "$tmpdir/debian.png" "$tmpdir/ubuntu.png" "$tmpdir/apt-cache.png"

# Docker cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "700x700" OUTPUT_FILE' "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" "$tmpdir/docker.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+175+275" -composite OUTPUT_FILE' "$tmpdir/cache.png" "$tmpdir/docker.png" "$tmpdir/docker-cache.png"
convert_image_full "$tmpdir/docker-cache.png" "$output_dir/docker-cache.png"
rm -f "$tmpdir/docker.png" "$tmpdir/docker-cache.png"

# Git cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "500x500" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/git.svg" "$tmpdir/git.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+275+275" -composite OUTPUT_FILE' "$tmpdir/cache.png" "$tmpdir/git.png" "$tmpdir/git-cache.png"
convert_image_full "$tmpdir/git-cache.png" "$output_dir/git-cache.png"
rm -f "$tmpdir/git.png" "$tmpdir/git-cache.png"

# NPM cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "750x750" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/npm.svg" "$tmpdir/npm.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+150+400" -composite OUTPUT_FILE' "$tmpdir/cache.png" "$tmpdir/npm.png" "$tmpdir/npm-cache.png"
convert_image_full "$tmpdir/npm-cache.png" "$output_dir/npm-cache.png"
rm -f "$tmpdir/npm.png" "$tmpdir/npm-cache.png"

# PyPi cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "600x600" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/python.svg" "$tmpdir/python.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+225+225" -composite OUTPUT_FILE' "$tmpdir/cache.png" "$tmpdir/python.png" "$tmpdir/pypi-cache.png"
convert_image_full "$tmpdir/pypi-cache.png" "$output_dir/pypi-cache.png"
rm -f "$tmpdir/python.png" "$tmpdir/pypi-cache.png"

# RubyGems cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "500x500" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/ruby.svg" "$tmpdir/ruby.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+275+300" -composite OUTPUT_FILE' "$tmpdir/cache.png" "$tmpdir/ruby.png" "$tmpdir/rubygems-cache.png"
convert_image_full "$tmpdir/rubygems-cache.png" "$output_dir/rubygems-cache.png"
rm -f "$tmpdir/ruby.png" "$tmpdir/rubygems-cache.png"

### Cloud ###

# APT remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "400x400" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/debian-linux.svg" "$tmpdir/debian.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "400x400" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/ubuntu-linux.svg" "$tmpdir/ubuntu.png"
convert_image_draft_3 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+250+175" -composite INPUT_FILE3 -gravity Center -geometry "-150+175" -composite OUTPUT_FILE' "$tmpdir/cloud.png" "$tmpdir/ubuntu.png" "$tmpdir/debian.png" "$tmpdir/apt-cloud.png"
convert_image_full "$tmpdir/apt-cloud.png" "$output_dir/apt-cloud.png"
rm -f "$tmpdir/debian.png" "$tmpdir/ubuntu.png" "$tmpdir/apt-cloud.png"

# Docker remote registry
convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize "600x600" OUTPUT_FILE' "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" "$tmpdir/docker.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+200+200" -composite OUTPUT_FILE' "$tmpdir/cloud.png" "$tmpdir/docker.png" "$tmpdir/docker-cloud.png"
convert_image_full "$tmpdir/docker-cloud.png" "$output_dir/docker-cloud.png"

# Git remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "500x500" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/git.svg" "$tmpdir/git.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+200+200" -composite OUTPUT_FILE' "$tmpdir/cloud.png" "$tmpdir/git.png" "$tmpdir/git-cloud.png"
convert_image_full "$tmpdir/git-cloud.png" "$output_dir/git-cloud.png"

# NPM remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "750x750" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/npm.svg" "$tmpdir/npm.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+100+200" -composite OUTPUT_FILE' "$tmpdir/cloud.png" "$tmpdir/npm.png" "$tmpdir/npm-cloud.png"
convert_image_full "$tmpdir/npm-cloud.png" "$output_dir/npm-cloud.png"

# PyPi remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "550x550" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/python.svg" "$tmpdir/python.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+200+200" -composite OUTPUT_FILE' "$tmpdir/cloud.png" "$tmpdir/python.png" "$tmpdir/pypi-cloud.png"
convert_image_full "$tmpdir/pypi-cloud.png" "$output_dir/pypi-cloud.png"

# RubyGems remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "400x400" OUTPUT_FILE' "$input_dir/gitman-repositories/dashboard-icons/svg/ruby.svg" "$tmpdir/ruby.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+275+150" -composite OUTPUT_FILE' "$tmpdir/cloud.png" "$tmpdir/ruby.png" "$tmpdir/rubygems-cloud.png"
convert_image_full "$tmpdir/rubygems-cloud.png" "$output_dir/rubygems-cloud.png"

## Prometheus exporters

# Apache prometheus exporter
cp "$input_dir/other/apache.svg.bin" "$tmpdir/apache.svg"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "800x800" OUTPUT_FILE' "$tmpdir/apache.svg" "$tmpdir/apache.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+325+150" -composite OUTPUT_FILE' "$tmpdir/prometheus-background.png" "$tmpdir/apache.png" "$tmpdir/apache-prometheus-exporter.png"
convert_image_full "$tmpdir/apache-prometheus-exporter.png" "$output_dir/apache-prometheus-exporter.png"

# PiHole prometheus exporter
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "600x600" OUTPUT_FILE' "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" "$tmpdir/pihole.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+325+225" -composite OUTPUT_FILE' "$tmpdir/prometheus-background.png" "$tmpdir/pihole.png" "$tmpdir/pihole-prometheus-exporter.png"
convert_image_full "$tmpdir/pihole-prometheus-exporter.png" "$output_dir/pihole-prometheus-exporter.png"

# Squid prometheus exporter
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "425x425" OUTPUT_FILE' "$output_dir/squid.png" "$tmpdir/squid.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+300+300" -composite OUTPUT_FILE' "$tmpdir/prometheus-background.png" "$tmpdir/squid.png" "$tmpdir/squid-prometheus-exporter.png"
convert_image_full "$tmpdir/squid-prometheus-exporter.png" "$output_dir/squid-prometheus-exporter.png"

### Cleanup ###

rm -rf "$tmpdir"
