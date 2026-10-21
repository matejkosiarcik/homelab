#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message || [ -n "${log_message}" ]; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}
# shellcheck disable=SC2248

mode=''
only_pattern=''
if [ "${HOMELAB_ENV-}" != '' ]; then
    mode="${HOMELAB_ENV}"
fi
while [ "${#}" -gt 0 ]; do
    case "${1}" in
    -d | --dev)
        mode='dev'
        shift
        ;;
    -p | --prod)
        mode='prod'
        shift
        ;;
    --only)
        only_pattern="${2}"
        shift 2
        ;;
    *)
        log ERROR "$(printf 'Unknown argument %s' "${1}")"
        exit 1
        ;;
    esac
done
HOMELAB_ENV="${mode}"

input_dir="$(git rev-parse --show-toplevel)/icons"
output_dir="$(git rev-parse --show-toplevel)/icons/prebuild"
if [ "${only_pattern:-}" = '' ]; then
    rm -rf "${output_dir}"
fi
mkdir -p "${output_dir}"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "${0}")/.build-utils.sh"

# shellcheck disable=SC2034
default_image_size='512x512'
# shellcheck disable=SC2034
default_convert_options='magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize RESOLUTION -density 2000 OUTPUT_FILE'

### Simple icons ###

# Cache
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 -border 50 OUTPUT_FILE' "${input_dir}/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/pvc.svg" "${tmpdir}/cache.png"
convert_image_full "${tmpdir}/cache.png" "${output_dir}/cache.png"

# Cloud
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 -border 20 OUTPUT_FILE' "${tmpdir}/13_05_osa_icons_svg/osa_cloud.svg" "${tmpdir}/cloud.png"
convert_image_full "${tmpdir}/cloud.png" "${output_dir}/cloud.png"

# Prometheus
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 -border 50 OUTPUT_FILE' "${input_dir}/gitman-repositories/homer-icons/svg/prometheus.svg" "${tmpdir}/prometheus-background.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 -border 20 OUTPUT_FILE' "${input_dir}/gitman-repositories/homer-icons/svg/prometheus.svg" "${tmpdir}/prometheus-alone.png"
convert_image_full "${tmpdir}/prometheus-alone.png" "${output_dir}/prometheus.png"

# Rounded Squid
convert_image_draft 'magick INPUT_FILE \( +clone -alpha extract -draw "fill black roundrectangle 0,0 %[w],%[h] 12,12" -negate \) -alpha off -compose CopyOpacity -composite OUTPUT_FILE' "${tmpdir}/other/squid.jpg" "${tmpdir}/squid.png"
convert_image_full "${tmpdir}/squid.png" "${output_dir}/squid.png"

### Combined icons ###

# PreBudget
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 -density 2000 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/png/actual-budget.png" "${tmpdir}/actualbudget.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 375x375 -density 2000 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/png/csv.png" "${tmpdir}/csv.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity SouthEast -geometry -25+0 -composite OUTPUT_FILE' "${tmpdir}/actualbudget.png" "${tmpdir}/csv.png" "${tmpdir}/prebudget.png"
convert_image_full "${tmpdir}/prebudget.png" "${output_dir}/prebudget.png"
rm -f "${tmpdir}/actualbudget.png" "${tmpdir}/csv.png" "${tmpdir}/prebudget.png"

# Servers
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 -border 10 -density 2000 OUTPUT_FILE' "${tmpdir}/13_05_osa_icons_svg/osa_server.svg" "${tmpdir}/servers-1.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 650x650 -density 2000 OUTPUT_FILE' "${tmpdir}/13_05_osa_icons_svg/osa_server.svg" "${tmpdir}/servers-2.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 550x550 -density 2000 OUTPUT_FILE' "${tmpdir}/13_05_osa_icons_svg/osa_server.svg" "${tmpdir}/servers-3.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry -200+175 -composite -resize 1000x1000 OUTPUT_FILE' "${tmpdir}/servers-1.png" "${tmpdir}/servers-2.png" "${tmpdir}/servers-4.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +200+225 -composite -resize 1000x1000 OUTPUT_FILE' "${tmpdir}/servers-4.png" "${tmpdir}/servers-3.png" "${tmpdir}/servers-5.png"
convert_image_full "${tmpdir}/servers-5.png" "${output_dir}/servers.png"
rm -f "${tmpdir}/servers-1.png" "${tmpdir}/servers-2.png" "${tmpdir}/servers-3.png" "${tmpdir}/servers-4.png" "${tmpdir}/servers-5.png"

# Personal devices
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 -border 10 -density 2000 OUTPUT_FILE' "${tmpdir}/13_05_osa_icons_svg/osa_laptop.svg" "${tmpdir}/laptop.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize "800x800" -density 2000 OUTPUT_FILE' "${tmpdir}/13_05_osa_icons_svg/osa_iPhone.svg" "${tmpdir}/phone.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +275+100 -composite -resize 1000x1000 OUTPUT_FILE' "${tmpdir}/laptop.png" "${tmpdir}/phone.png" "${tmpdir}/personal-devices.png"
convert_image_full "${tmpdir}/personal-devices.png" "${output_dir}/personal-devices.png"
rm -f "${tmpdir}/personal-devices.png"

### Icons with background ###

magick -size 1000x1000 xc:#ffffffef "${tmpdir}/white-background.png"
magick -size 1000x1000 xc:black -fill white -draw "roundRectangle 0,0,1000,1000 80,80" "${tmpdir}/white-background-mask.png"
magick "${tmpdir}/white-background.png" "${tmpdir}/white-background-mask.png" -alpha Off -compose CopyOpacity -composite "${tmpdir}/white-background.png"
magick "${tmpdir}/white-background.png" -define png:color-type=6 "${tmpdir}/white-background.png"

# DWService with custom background
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 900x900 -density 2000 OUTPUT_FILE' "${tmpdir}/other/dwservice.png" "${tmpdir}/dwservice-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -composite OUTPUT_FILE' "${tmpdir}/white-background.png" "${tmpdir}/dwservice-foreground.png" "${tmpdir}/dwservice.png"
convert_image_full "${tmpdir}/dwservice.png" "${output_dir}/dwservice.png"
rm -f "${tmpdir}/dwservice-foreground.png" "${tmpdir}/dwservice.png"

# Let's Encrypt
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 900x900 -density 2000 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/lets-encrypt.svg" "${tmpdir}/lets-encrypt-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +0+0 -composite OUTPUT_FILE' "${tmpdir}/white-background.png" "${tmpdir}/lets-encrypt-foreground.png" "${tmpdir}/lets-encrypt.png"
convert_image_full "${tmpdir}/lets-encrypt.png" "${output_dir}/lets-encrypt.png"
rm -f "${tmpdir}/lets-encrypt-foreground.png" "${tmpdir}/lets-encrypt.png"

# LibreTranslate
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 850x850 -density 2000 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/libretranslate.svg" "${tmpdir}/libretranslate-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +0+0 -composite OUTPUT_FILE' "${tmpdir}/white-background.png" "${tmpdir}/libretranslate-foreground.png" "${tmpdir}/libretranslate.png"
convert_image_full "${tmpdir}/libretranslate.png" "${output_dir}/libretranslate.png"
rm -f "${tmpdir}/libretranslate-foreground.png" "${tmpdir}/libretranslate.png"

# Ollama
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 -density 2000 OUTPUT_FILE' "${tmpdir}/other/openwebui.png" "${tmpdir}/openwebui-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +0+0 -composite OUTPUT_FILE' "${tmpdir}/white-background.png" "${tmpdir}/openwebui-foreground.png" "${tmpdir}/openwebui.png"
convert_image_full "${tmpdir}/openwebui.png" "${output_dir}/openwebui.png"
rm -f "${tmpdir}/openwebui-foreground.png" "${tmpdir}/openwebui.png"

# Open WebUI
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 850x850 -density 2000 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/ollama.svg" "${tmpdir}/ollama-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +0+0 -composite OUTPUT_FILE' "${tmpdir}/white-background.png" "${tmpdir}/ollama-foreground.png" "${tmpdir}/ollama.png"
convert_image_full "${tmpdir}/ollama.png" "${output_dir}/ollama.png"
rm -f "${tmpdir}/ollama-foreground.png" "${tmpdir}/ollama.png"

# Smtp4dev with custom background
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 875x875 -density 2000 OUTPUT_FILE' "${tmpdir}/other/smtp4dev-custom.png" "${tmpdir}/smtp4dev-foreground.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +0+0 -composite OUTPUT_FILE' "${tmpdir}/white-background.png" "${tmpdir}/smtp4dev-foreground.png" "${tmpdir}/smtp4dev.png"
convert_image_full "${tmpdir}/smtp4dev.png" "${output_dir}/smtp4dev.png"
rm -f "${tmpdir}/smtp4dev-foreground.png" "${tmpdir}/smtp4dev.png"

### Cronjobs ###

# Certificator
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 -density 2000 OUTPUT_FILE' "${input_dir}/prebuild/lets-encrypt.png" "${tmpdir}/lets-encrypt.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 350x350 -density 2000 OUTPUT_FILE' "${input_dir}/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/cronjob.svg" "${tmpdir}/cronjob.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity NorthEast -geometry +0+0 -composite -resize 1000x1000 OUTPUT_FILE' "${tmpdir}/lets-encrypt.png" "${tmpdir}/cronjob.png" "${tmpdir}/certificator.png"
convert_image_full "${tmpdir}/certificator.png" "${output_dir}/certificator.png"

### Layered diagram icons ###

# Backup script
if should_generate_icon "${input_dir}/gitman-repositories/homer-icons/png/chromium.png" "${input_dir}/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/cronjob.svg" "${tmpdir}/other/playwright.svg" "${output_dir}/backup-script.png"; then
    magick -size 1000x1000 xc:none \
        \( "${input_dir}/gitman-repositories/homer-icons/png/chromium.png" -background none -resize 1000x1000 \) -gravity Center -geometry +0+0 -composite \
        \( "${input_dir}/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/cronjob.svg" -background none -resize 400x400 \) -gravity NorthEast -geometry +0+0 -composite \
        \( "${tmpdir}/other/playwright.svg" -background none -resize 600x600 \) -gravity SouthEast -geometry +63+125 -composite \
        "${tmpdir}/backup-script.png"
    convert_image_full "${tmpdir}/backup-script.png" "${output_dir}/backup-script.png"
    rm -f "${tmpdir}/backup-script.png"
fi

# Docker registry
if should_generate_icon "${input_dir}/prebuild/cloud.png" "${input_dir}/gitman-repositories/homer-icons/png/docker-moby.png" "${output_dir}/docker-registry.png"; then
    magick -size 1000x1000 xc:none \
        \( "${input_dir}/prebuild/cloud.png" -background none -resize 1000x1000 \) -gravity Center -geometry +0+0 -composite \
        \( "${input_dir}/gitman-repositories/homer-icons/png/docker-moby.png" -background none -resize 625x625 \) -gravity SouthEast -geometry +0+0 -composite \
        "${tmpdir}/docker-registry.png"
    convert_image_full "${tmpdir}/docker-registry.png" "${output_dir}/docker-registry.png"
    rm -f "${tmpdir}/docker-registry.png"
fi

# Dozzle agents
if should_generate_icon "${input_dir}/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/job.svg" "${input_dir}/gitman-repositories/homer-icons/png/dozzle.png" "${output_dir}/dozzle-agents.png"; then
    magick -size 1000x1000 xc:none \
        \( "${input_dir}/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/job.svg" -background none -resize 1000x1000 \) -gravity Center -geometry +0+0 -composite \
        \( "${input_dir}/gitman-repositories/homer-icons/png/dozzle.png" -background none -resize 500x500 \) -gravity SouthEast -geometry +0+63 -composite \
        "${tmpdir}/dozzle-agents.png"
    convert_image_full "${tmpdir}/dozzle-agents.png" "${output_dir}/dozzle-agents.png"
    rm -f "${tmpdir}/dozzle-agents.png"
fi

# Public DNS
if should_generate_icon "${input_dir}/prebuild/cloud.png" "${input_dir}/gitman-repositories/homer-icons/png/azuredns.png" "${output_dir}/public-dns.png"; then
    magick -size 1000x1000 xc:none \
        \( "${input_dir}/prebuild/cloud.png" -background none -resize 1000x1000 \) -gravity Center -geometry +0+0 -composite \
        \( "${input_dir}/gitman-repositories/homer-icons/png/azuredns.png" -background none -resize 500x500 \) -gravity Center -geometry +250+125 -composite \
        "${tmpdir}/public-dns.png"
    convert_image_full "${tmpdir}/public-dns.png" "${output_dir}/public-dns.png"
    rm -f "${tmpdir}/public-dns.png"
fi

# ReportPortal migrations
if should_generate_icon "${tmpdir}/other/reportportal.svg" "${input_dir}/gitman-repositories/bash-logo/assets/Logos/Icons/SVG/512x512_white.svg" "${output_dir}/reportportal-migrations.png"; then
    # TODO: Merge this call into a single magick call
    convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 1000x1000 OUTPUT_FILE' "${tmpdir}/other/reportportal.svg" "${tmpdir}/reportportal.png"
    magick -size 1000x1000 xc:none \
        \( "${tmpdir}/reportportal.png" -background none -resize 812x812 \) -gravity NorthWest -geometry +0+200 -composite \
        \( "${input_dir}/gitman-repositories/bash-logo/assets/Logos/Icons/SVG/512x512_white.svg" -background none -resize 400x400 \) -gravity NorthEast -geometry +0+0 -composite \
        "${tmpdir}/reportportal-migrations.png"
    convert_image_full "${tmpdir}/reportportal-migrations.png" "${output_dir}/reportportal-migrations.png"
    rm -f "${tmpdir}/reportportal-migrations.png"
fi

# RenovateBot cronjob
if should_generate_icon "${tmpdir}/other/renovatebot.png" "${input_dir}/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/cronjob.svg" "${output_dir}/renovatebot-cronjob.png"; then
    magick -size 1000x1000 xc:none \
        \( "${tmpdir}/other/renovatebot.png" -background none -resize 1000x1000 \) -gravity Center -geometry +0+0 -composite \
        \( "${input_dir}/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/cronjob.svg" -background none -resize 400x400 \) -gravity NorthEast -geometry +0+0 -composite \
        "${tmpdir}/renovatebot-cronjob.png"
    convert_image_full "${tmpdir}/renovatebot-cronjob.png" "${output_dir}/renovatebot-cronjob.png"
    rm -f "${tmpdir}/renovatebot-cronjob.png"
fi

# Smart home devices
if should_generate_icon "${tmpdir}/13_05_osa_icons_svg/osa_home.svg" "${tmpdir}/other/iot.png" "${output_dir}/smart-home-devices.png"; then
    magick -size 1000x1000 xc:none \
        \( "${tmpdir}/13_05_osa_icons_svg/osa_home.svg" -background none -resize 1000x1000 \) -gravity Center -geometry +0+0 -composite \
        \( "${tmpdir}/other/iot.png" -background none -resize 600x600 \) -gravity NorthEast -geometry +20+20 -composite \
        "${tmpdir}/smart-home-devices.png"
    convert_image_full "${tmpdir}/smart-home-devices.png" "${output_dir}/smart-home-devices.png"
    rm -f "${tmpdir}/smart-home-devices.png"
fi

### Cache ###

# APT cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 450x450 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/debian-linux.svg" "${tmpdir}/debian.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 450x450 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/ubuntu-linux.svg" "${tmpdir}/ubuntu.png"
convert_image_draft_3 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +225+300 -composite INPUT_FILE3 -gravity Center -geometry "-225+300" -composite OUTPUT_FILE' "${tmpdir}/cache.png" "${tmpdir}/ubuntu.png" "${tmpdir}/debian.png" "${tmpdir}/apt-cache.png"
convert_image_full "${tmpdir}/apt-cache.png" "${output_dir}/apt-cache.png"
rm -f "${tmpdir}/debian.png" "${tmpdir}/ubuntu.png" "${tmpdir}/apt-cache.png"

# Docker cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 700x700 OUTPUT_FILE' "${input_dir}/gitman-repositories/homer-icons/png/docker-moby.png" "${tmpdir}/docker.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +175+275 -composite OUTPUT_FILE' "${tmpdir}/cache.png" "${tmpdir}/docker.png" "${tmpdir}/docker-cache.png"
convert_image_full "${tmpdir}/docker-cache.png" "${output_dir}/docker-cache.png"
rm -f "${tmpdir}/docker.png" "${tmpdir}/docker-cache.png"

# Git cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 500x500 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/git.svg" "${tmpdir}/git.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +275+275 -composite OUTPUT_FILE' "${tmpdir}/cache.png" "${tmpdir}/git.png" "${tmpdir}/git-cache.png"
convert_image_full "${tmpdir}/git-cache.png" "${output_dir}/git-cache.png"
rm -f "${tmpdir}/git.png" "${tmpdir}/git-cache.png"

# NPM cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 750x750 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/npm.svg" "${tmpdir}/npm.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +150+400 -composite OUTPUT_FILE' "${tmpdir}/cache.png" "${tmpdir}/npm.png" "${tmpdir}/npm-cache.png"
convert_image_full "${tmpdir}/npm-cache.png" "${output_dir}/npm-cache.png"
rm -f "${tmpdir}/npm.png" "${tmpdir}/npm-cache.png"

# PyPi cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 600x600 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/python.svg" "${tmpdir}/python.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +225+225 -composite OUTPUT_FILE' "${tmpdir}/cache.png" "${tmpdir}/python.png" "${tmpdir}/pypi-cache.png"
convert_image_full "${tmpdir}/pypi-cache.png" "${output_dir}/pypi-cache.png"
rm -f "${tmpdir}/python.png" "${tmpdir}/pypi-cache.png"

# RubyGems cache proxy
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 500x500 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/ruby.svg" "${tmpdir}/ruby.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +275+300 -composite OUTPUT_FILE' "${tmpdir}/cache.png" "${tmpdir}/ruby.png" "${tmpdir}/rubygems-cache.png"
convert_image_full "${tmpdir}/rubygems-cache.png" "${output_dir}/rubygems-cache.png"
rm -f "${tmpdir}/ruby.png" "${tmpdir}/rubygems-cache.png"

### Cloud ###

# APT remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 400x400 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/debian-linux.svg" "${tmpdir}/debian.png"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 400x400 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/ubuntu-linux.svg" "${tmpdir}/ubuntu.png"
convert_image_draft_3 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +250+175 -composite INPUT_FILE3 -gravity Center -geometry "-150+175" -composite OUTPUT_FILE' "${tmpdir}/cloud.png" "${tmpdir}/ubuntu.png" "${tmpdir}/debian.png" "${tmpdir}/apt-cloud.png"
convert_image_full "${tmpdir}/apt-cloud.png" "${output_dir}/apt-cloud.png"
rm -f "${tmpdir}/debian.png" "${tmpdir}/ubuntu.png" "${tmpdir}/apt-cloud.png"

# Docker remote registry
convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 600x600 OUTPUT_FILE' "${input_dir}/gitman-repositories/homer-icons/png/docker-moby.png" "${tmpdir}/docker.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +200+200 -composite OUTPUT_FILE' "${tmpdir}/cloud.png" "${tmpdir}/docker.png" "${tmpdir}/docker-cloud.png"
convert_image_full "${tmpdir}/docker-cloud.png" "${output_dir}/docker-cloud.png"

# Git remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 500x500 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/git.svg" "${tmpdir}/git.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +200+200 -composite OUTPUT_FILE' "${tmpdir}/cloud.png" "${tmpdir}/git.png" "${tmpdir}/git-cloud.png"
convert_image_full "${tmpdir}/git-cloud.png" "${output_dir}/git-cloud.png"

# NPM remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 750x750 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/npm.svg" "${tmpdir}/npm.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +100+200 -composite OUTPUT_FILE' "${tmpdir}/cloud.png" "${tmpdir}/npm.png" "${tmpdir}/npm-cloud.png"
convert_image_full "${tmpdir}/npm-cloud.png" "${output_dir}/npm-cloud.png"

# PyPi remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 550x550 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/python.svg" "${tmpdir}/python.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +200+200 -composite OUTPUT_FILE' "${tmpdir}/cloud.png" "${tmpdir}/python.png" "${tmpdir}/pypi-cloud.png"
convert_image_full "${tmpdir}/pypi-cloud.png" "${output_dir}/pypi-cloud.png"

# RubyGems remote registry
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 400x400 OUTPUT_FILE' "${input_dir}/gitman-repositories/dashboard-icons/svg/ruby.svg" "${tmpdir}/ruby.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +275+150 -composite OUTPUT_FILE' "${tmpdir}/cloud.png" "${tmpdir}/ruby.png" "${tmpdir}/rubygems-cloud.png"
convert_image_full "${tmpdir}/rubygems-cloud.png" "${output_dir}/rubygems-cloud.png"

## Prometheus exporters

# Apache prometheus exporter
cp "${tmpdir}/other/apache.svg" "${tmpdir}/apache.svg"
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 800x800 OUTPUT_FILE' "${tmpdir}/apache.svg" "${tmpdir}/apache.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry "+325+150" -composite OUTPUT_FILE' "${tmpdir}/prometheus-background.png" "${tmpdir}/apache.png" "${tmpdir}/apache-prometheus-exporter.png"
convert_image_full "${tmpdir}/apache-prometheus-exporter.png" "${output_dir}/apache-prometheus-exporter.png"

# PiHole prometheus exporter
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 600x600 OUTPUT_FILE' "${input_dir}/gitman-repositories/organizr/plugins/images/tabs/pihole.png" "${tmpdir}/pihole.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +325+225 -composite OUTPUT_FILE' "${tmpdir}/prometheus-background.png" "${tmpdir}/pihole.png" "${tmpdir}/pihole-prometheus-exporter.png"
convert_image_full "${tmpdir}/pihole-prometheus-exporter.png" "${output_dir}/pihole-prometheus-exporter.png"

# Squid prometheus exporter
convert_image_draft 'magick -density 2000 -background none -bordercolor transparent INPUT_FILE -resize 425x425 OUTPUT_FILE' "${output_dir}/squid.png" "${tmpdir}/squid.png"
convert_image_draft_2 'magick INPUT_FILE1 INPUT_FILE2 -gravity Center -geometry +300+300 -composite OUTPUT_FILE' "${tmpdir}/prometheus-background.png" "${tmpdir}/squid.png" "${tmpdir}/squid-prometheus-exporter.png"
convert_image_full "${tmpdir}/squid-prometheus-exporter.png" "${output_dir}/squid-prometheus-exporter.png"

# Cleanup reused icons
rm -f "${tmpdir}/cache.png" "${tmpdir}/cloud.png" "${tmpdir}/prometheus-background.png" "${tmpdir}/prometheus-alone.png" "${tmpdir}/squid.png"

### Cleanup ###

rm -rf "${tmpdir}"
unset tmpdir
