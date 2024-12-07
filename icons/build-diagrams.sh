#!/bin/sh
set -euf
# shellcheck disable=SC2248

input_dir="$(git rev-parse --show-toplevel)/icons"
output_dir="$(git rev-parse --show-toplevel)/docs/diagrams/icons"
rm -rf "$output_dir"
mkdir -p "$output_dir"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

# shellcheck disable=SC2034
default_image_size='256x256'
# shellcheck disable=SC2034
default_convert_options='magick -background none -bordercolor transparent INPUT_FILE -resize RESOLUTION -density 1200 OUTPUT_FILE'

### Bash icon ###

convert_image_full "$input_dir/gitman-repositories/bash-logo/assets/Logos/Icons/SVG/512x512.svg" "$output_dir/bash.png"

### OSA Icons ###

convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_cloud.svg" "$output_dir/cloud.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_home.svg" "$output_dir/home.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$output_dir/lightbulb.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_hub.svg" "$output_dir/network.png"

### Dashboard Icons ###

convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/dozzle.svg" "$output_dir/dozzle.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/gitlab.png" "$output_dir/gitlab.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/homepage.png" "$output_dir/homepage.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/lets-encrypt.svg" "$output_dir/lets-encrypt.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/ntfy.svg" "$output_dir/ntfy.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/openspeedtest.png" "$output_dir/openspeedtest.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/pi-alert.png" "$output_dir/pialert.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/watchyourlan.png" "$output_dir/watchyourlan.png"

### Organizr Icons ###

convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/healthchecks.png" "$output_dir/healthchecks.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/homeassistant.png" "$output_dir/homeassistant.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" "$output_dir/pihole.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/speedtest-icon.png" "$output_dir/speedtest-tracker.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/unifi-protect.png" "$output_dir/unifi-protect.png"

### Kubernetes Icons ###

convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/job.svg" "$output_dir/apps.png"
convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/cronjob.svg" "$output_dir/cronjob.png"
convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/vol.svg" "$output_dir/database.png"
convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ing.svg" "$output_dir/ingress.png"
convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ns.svg" "$output_dir/placeholder.png"

### Homer icons ###

convert_image_full "$input_dir/gitman-repositories/homer-icons/png/changedetection.png" "$output_dir/changedetection.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/chromium.png" "$output_dir/chromium.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" "$output_dir/docker.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/azuredns.png" "$output_dir/dns.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/filebrowser.svg" "$output_dir/filebrowser.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/github.svg" "$output_dir/github.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/jellyfin.svg" "$output_dir/jellyfin.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/minio.png" "$output_dir/minio.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/mongodb.svg" "$output_dir/mongodb.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/motioneye.png" "$output_dir/motioneye.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" "$output_dir/prometheus.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/omada.png" "$output_dir/tp-link-omada.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/tplink.png" "$output_dir/tp-link.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/tvheadend.png" "$output_dir/tvheadend.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/ubiquiti.svg" "$output_dir/unifi.png"

### Other Icons ###

convert_image_full "$input_dir/other/actualbudget.png" "$output_dir/actualbudget.png"
convert_image_full "$input_dir/other/apache.svg.bin" "$output_dir/apache.png"
convert_image_full "$input_dir/other/button.png" "$output_dir/button.png"
convert_image_full "$input_dir/other/gatus.png" "$output_dir/gatus.png"
convert_image_full "$input_dir/other/iot.png" "$output_dir/iot.png"
convert_image_full "$input_dir/other/litestream-custom.svg.bin" "$output_dir/litestream.png"
convert_image_full "$input_dir/other/playwright.svg.bin" "$output_dir/playwright.png"
convert_image_full "$input_dir/other/raspberry-pi.svg.bin" "$output_dir/raspberry-pi.png"
convert_image_full "$input_dir/other/renovatebot.png" "$output_dir/renovatebot.png"
convert_image_full "$input_dir/other/smtp4dev-custom.png" "$output_dir/smtp4dev.png"
convert_image_full "$input_dir/other/ssl-certificate.png" "$output_dir/ssl-certificate.png"
convert_image_full "$input_dir/other/webcamera.png" "$output_dir/webcamera.png"

### Combined icons ###

convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 256x256 -border 32 -density 1200 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_server.svg" "$tmpdir/server-1.png"
convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 96x96 -border 32 -density 1200 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_server.svg" "$tmpdir/server-2.png"
convert_image_draft 'magick INPUT_FILE -gravity Center -geometry 256x256+50+80 -composite -resize 256x256 OUTPUT_FILE' "$tmpdir/server-1.png $tmpdir/server-2.png" "$tmpdir/servers-1.png"
convert_image_draft 'magick INPUT_FILE -gravity Center -geometry 256x256-50+40 -composite -resize 256x256 OUTPUT_FILE' "$tmpdir/servers-1.png $tmpdir/server-2.png" "$tmpdir/servers-2.png"
convert_image_full "$tmpdir/servers-2.png" "$output_dir/servers.png"

convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 256x256 -border 32 -density 1200 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_laptop.svg" "$tmpdir/laptop.png"
convert_image_draft 'magick -background none -bordercolor transparent INPUT_FILE -resize 192x192 -border 32 -density 1200 OUTPUT_FILE' "$tmpdir/13_05_osa_icons_svg/osa_iPhone.svg" "$tmpdir/phone.png"
convert_image_draft 'magick INPUT_FILE -gravity Center -geometry 256x256+70+30 -composite -resize 256x256 OUTPUT_FILE' "$tmpdir/laptop.png $tmpdir/phone.png" "$tmpdir/personal-devices.png"
convert_image_full "$tmpdir/personal-devices.png" "$output_dir/personal-devices.png"

### Cleanup ###

rm -rf "$tmpdir"
