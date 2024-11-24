#!/bin/sh
set -euf
# shellcheck disable=SC2248

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

input_dir="$(git rev-parse --show-toplevel)/icons"
outdir="$(git rev-parse --show-toplevel)/docs/diagrams/icons"
rm -rf "$outdir"
mkdir -p "$outdir"

convert_options='magick -background none -bordercolor transparent INPUT_FILE -resize 256x256 -density 1200 OUTPUT_FILE'

### Bash icon ###

convert_image "$convert_options" "$input_dir/gitman-repositories/bash-logo/assets/Logos/Icons/SVG/512x512.svg" "$outdir/bash.png"

### OSA Icons ###

convert_image "$convert_options" "$tmpdir/13_05_osa_icons_svg/osa_cloud.svg" "$outdir/cloud.png"
convert_image "$convert_options" "$tmpdir/13_05_osa_icons_svg/osa_home.svg" "$outdir/home.png"
convert_image "$convert_options" "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$outdir/lightbulb.png"
convert_image "$convert_options" "$tmpdir/13_05_osa_icons_svg/osa_hub.svg" "$outdir/network.png"

### Dashboard Icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/dashboard-icons/svg/dozzle.svg" "$outdir/dozzle.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/dashboard-icons/png/gitlab.png" "$outdir/gitlab.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/dashboard-icons/png/homepage.png" "$outdir/homepage.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/dashboard-icons/svg/ntfy.svg" "$outdir/ntfy.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/dashboard-icons/png/openspeedtest.png" "$outdir/openspeedtest.png"

### Organizr Icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/healthchecks.png" "$outdir/healthchecks.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/homeassistant.png" "$outdir/homeassistant.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" "$outdir/pihole.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/speedtest-icon.png" "$outdir/speedtest-tracker.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/organizr/plugins/images/tabs/unifi-protect.png" "$outdir/unifi-protect.png"

### Kubernetes Icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/job.svg" "$outdir/apps.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/cronjob.svg" "$outdir/cronjob.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/vol.svg" "$outdir/database.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ing.svg" "$outdir/ingress.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ns.svg" "$outdir/placeholder.png"

### Homer icons ###

convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/changedetection.png" "$outdir/changedetection.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/chromium.png" "$outdir/chromium.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" "$outdir/docker.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/azuredns.png" "$outdir/dns.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/filebrowser.svg" "$outdir/filebrowser.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/github.svg" "$outdir/github.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/jellyfin.svg" "$outdir/jellyfin.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/letencrypt.png" "$outdir/lets-encrypt.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/minio.png" "$outdir/minio.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/mongodb.svg" "$outdir/mongodb.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" "$outdir/prometheus.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/omada.png" "$outdir/tp-link-omada.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/tplink.png" "$outdir/tp-link.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/png/tvheadend.png" "$outdir/tvheadend.png"
convert_image "$convert_options" "$input_dir/gitman-repositories/homer-icons/svg/ubiquiti.svg" "$outdir/unifi.png"

### Other Icons ###

convert_image "$convert_options" "$input_dir/other/actualbudget.png" "$outdir/actualbudget.png"
convert_image "$convert_options" "$input_dir/other/apache.svg.bin" "$outdir/apache.png"
convert_image "$convert_options" "$input_dir/other/button.png" "$outdir/button.png"
convert_image "$convert_options" "$input_dir/other/gatus.png" "$outdir/gatus.png"
convert_image "$convert_options" "$input_dir/other/iot.png" "$outdir/iot.png"
convert_image "$convert_options" "$input_dir/other/litestream - custom.svg.bin" "$outdir/litestream.png"
convert_image "$convert_options" "$input_dir/other/playwright.svg.bin" "$outdir/playwright.png"
convert_image "$convert_options" "$input_dir/other/raspberry-pi.svg.bin" "$outdir/raspberry-pi.png"
convert_image "$convert_options" "$input_dir/other/renovatebot.png" "$outdir/renovatebot.png"
convert_image "$convert_options" "$input_dir/other/smtp4dev - custom.png" "$outdir/smtp4dev.png"

### Combined icons ###

convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 256x256 -border 32 -density 1200 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_server.svg" "$tmpdir/server-1.png"
convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 96x96 -border 32 -density 1200 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_server.svg" "$tmpdir/server-2.png"
convert_image_draft "magick $tmpdir/server-1.png $tmpdir/server-2.png -gravity Center -geometry 256x256+50+80 -composite -resize 256x256 OUTPUT_FILE" '' "$tmpdir/servers.png"
convert_image "magick $tmpdir/servers.png $tmpdir/server-2.png -gravity Center -geometry 256x256-50+40 -composite -resize 256x256 OUTPUT_FILE" '' "$outdir/servers.png"

convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 256x256 -border 32 -density 1200 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_laptop.svg" "$tmpdir/laptop.png"
convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 192x192 -border 32 -density 1200 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_iPhone.svg" "$tmpdir/phone.png"
convert_image_draft "magick $tmpdir/laptop.png $tmpdir/phone.png -gravity Center -geometry 256x256+70+30 -composite -resize 256x256 OUTPUT_FILE" '' "$outdir/personal-devices.png"

### Cleanup ###

rm -rf "$tmpdir"
