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

convert_image_full "$input_dir/gitman-repositories/bash-logo/assets/Logos/Icons/SVG/512x512_white.svg" "$output_dir/bash.png"

### Dashboard Icons ###

convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/aws.svg" "$output_dir/aws.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/azure.svg" "$output_dir/azure.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/caddy.svg" "$output_dir/caddy.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/cloudflare.svg" "$output_dir/cloudflare.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/datadog.svg" "$output_dir/datadog.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/debian-linux.svg" "$output_dir/debian.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/digital-ocean.svg" "$output_dir/digitalocean.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/fedora.svg" "$output_dir/fedora.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/files.svg" "$output_dir/files.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/filezilla.svg" "$output_dir/filezilla.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/gitea.svg" "$output_dir/gitea.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/gitlab.png" "$output_dir/gitlab.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/glances.svg" "$output_dir/glances.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/google-cloud-platform.svg" "$output_dir/google-cloud.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/gotify.svg" "$output_dir/gotify.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/grafana.svg" "$output_dir/grafana.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/graylog.svg" "$output_dir/graylog.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/homepage.png" "$output_dir/homepage.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/immich.svg" "$output_dir/immich.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/jenkins.svg" "$output_dir/jenkins.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/kiwix-light.svg" "$output_dir/kiwix.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/linode.svg" "$output_dir/linode.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/linux.svg" "$output_dir/linux.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/loki.svg" "$output_dir/loki.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/nagios.svg" "$output_dir/nagios.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/netdata.svg" "$output_dir/netdata.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/netalertx.png" "$output_dir/netalertx.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/nextcloud.svg" "$output_dir/nextcloud.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/nginx.svg" "$output_dir/nginx.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/ntfy.svg" "$output_dir/ntfy.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/openspeedtest.png" "$output_dir/openspeedtest.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/opensuse.svg" "$output_dir/opensuse.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/owncloud.svg" "$output_dir/owncloud.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/owntracks.svg" "$output_dir/owntracks.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/pagerduty.svg" "$output_dir/pagerduty.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/pi-alert.png" "$output_dir/pialert.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/podman.svg" "$output_dir/podman.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/portainer.svg" "$output_dir/portainer.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/redhat-linux.svg" "$output_dir/redhat.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/samba-server.svg" "$output_dir/samba.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/ubuntu-linux.svg" "$output_dir/ubuntu.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/unbound.svg" "$output_dir/unbound.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/vaultwarden-light.svg" "$output_dir/vaultwarden.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/vikunja.svg" "$output_dir/vikunja.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/vultr.svg" "$output_dir/vultr.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/wikipedia-light.svg" "$output_dir/wikipedia.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/windows-11.png" "$output_dir/windows.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/zabbix.svg" "$output_dir/zabbix.png"

### Homer icons ###

convert_image_full "$input_dir/gitman-repositories/homer-icons/png/cadvisor.png" "$output_dir/cadvisor.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/changedetection.png" "$output_dir/changedetection.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/chrome.svg" "$output_dir/chrome.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/chromium.png" "$output_dir/chromium.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" "$output_dir/docker.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/dozzle.png" "$output_dir/dozzle.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/azuredns.png" "$output_dir/dns.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/filebrowser.svg" "$output_dir/filebrowser.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/jellyfin.svg" "$output_dir/jellyfin.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/minio.png" "$output_dir/minio.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/mongodb.svg" "$output_dir/mongodb.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/motioneye.png" "$output_dir/motioneye.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/omada.png" "$output_dir/tp-link-omada.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" "$output_dir/prometheus.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/tp-link.png" "$output_dir/tp-link.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/tvheadend.png" "$output_dir/tvheadend.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/ubiquiti.svg" "$output_dir/unifi.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/uptime-kuma.svg" "$output_dir/uptime-kuma.png"

magick -background none -bordercolor transparent "$input_dir/gitman-repositories/homer-icons/svg/github.svg" -resize "$default_image_size" -density 1200 -fill black -colorize 100% "$tmpdir/github-tmp.png"
convert_image_full "$tmpdir/github-tmp.png" "$output_dir/github.png"

### Kubernetes Icons ###

convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/job.svg" "$output_dir/apps.png"
convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/cronjob.svg" "$output_dir/cronjob.png"
convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/vol.svg" "$output_dir/database.png"
convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ing.svg" "$output_dir/ingress.png"
convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ns.svg" "$output_dir/placeholder.png"

### Organizr Icons ###

convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/healthchecks.png" "$output_dir/healthchecks.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/homeassistant.png" "$output_dir/home-assistant.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" "$output_dir/pihole.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/speedtest-icon.png" "$output_dir/speedtest-tracker.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/unifi-protect.png" "$output_dir/unifi-protect.png"

### OSA Icons ###

convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_cloud.svg" "$output_dir/cloud.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_home.svg" "$output_dir/home.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$output_dir/lightbulb.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_hub.svg" "$output_dir/network.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_iPhone.svg" "$output_dir/phone.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_device-usb.svg" "$output_dir/usb.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_device-usb-wifi.svg" "$output_dir/usb-wifi.png"

## VRT Icons ##

perl -0pe 's~<g id="id3">.+?</g>~~gms' <"$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Clients & Peripherals/Laptop 3.svg" >"$tmpdir/notebook.svg"
convert_image_full "$tmpdir/notebook.svg" "$output_dir/notebook.png"
rm -f "$tmpdir/notebook.svg"

perl -0pe 's~<g id="id3">.+?</g>~~gms' <"$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Router.svg" >"$tmpdir/router.png"
convert_image_full "$tmpdir/router.png" "$output_dir/router.png"
rm -f "$tmpdir/router.png"

perl -0pe 's~<g id="id3">.+?</g>~~gms' <"$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Switch 2.svg" >"$tmpdir/switch.png"
convert_image_full "$tmpdir/switch.png" "$output_dir/switch.png"
rm -f "$tmpdir/switch.png"

perl -0pe 's~<g id="id3">.+?</g>~~gms' <"$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Wireless Access Point 2.svg" >"$tmpdir/wifi-ap.png"
convert_image_full "$tmpdir/wifi-ap.png" "$output_dir/wifi-ap.png"
rm -f "$tmpdir/wifi-ap.png"

perl -0pe 's~<g id="id3">.+?</g>~~gms' <"$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Servers/Tower Server 1.svg" >"$tmpdir/server-big.png"
convert_image_full "$tmpdir/server-big.png" "$output_dir/server-big.png"
rm -f "$tmpdir/server-big.png"

perl -0pe 's~<g id="id3">.+?</g>~~gms' <"$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Servers/Appliance 1.svg" >"$tmpdir/server-small.png"
convert_image_full "$tmpdir/server-small.png" "$output_dir/server-small.png"
rm -f "$tmpdir/server-small.png"

## Other Icons ###

convert_image_full "$input_dir/other/actualbudget.png" "$output_dir/actualbudget.png"
convert_image_full "$input_dir/other/antenna.png" "$output_dir/antenna.png"
convert_image_full "$input_dir/other/antennas.png" "$output_dir/antennas.png"
convert_image_full "$input_dir/other/apache.svg.bin" "$output_dir/apache.png"
convert_image_full "$input_dir/other/api.png" "$output_dir/api.png"
convert_image_full "$input_dir/other/automatic1111.png" "$output_dir/automatic1111.png"
convert_image_full "$input_dir/other/button.png" "$output_dir/button.png"
convert_image_full "$input_dir/other/gatus.png" "$output_dir/gatus.png"
convert_image_full "$input_dir/other/graphics-card.png" "$output_dir/graphics-card.png"
convert_image_full "$input_dir/other/iot.png" "$output_dir/iot.png"
convert_image_full "$input_dir/other/litestream-custom.svg.bin" "$output_dir/litestream.png"
convert_image_full "$input_dir/other/odroid.png" "$output_dir/odroid.png"
convert_image_full "$input_dir/other/old-tv.png" "$output_dir/old-tv.png"
convert_image_full "$input_dir/other/open-router.png" "$output_dir/open-router.png"
convert_image_full "$input_dir/other/photos.png" "$output_dir/photos.png"
convert_image_full "$input_dir/other/picture.png" "$output_dir/picture.png"
convert_image_full "$input_dir/other/playwright.svg.bin" "$output_dir/playwright.png"
convert_image_full "$input_dir/other/raspberry-pi.svg.bin" "$output_dir/raspberry-pi.png"
convert_image_full "$input_dir/other/stable-diffusion.png" "$output_dir/stable-diffusion.png"
convert_image_full "$input_dir/other/renovatebot.png" "$output_dir/renovatebot.png"
convert_image_full "$input_dir/other/webcamera.png" "$output_dir/webcamera.png"
convert_image_full "$input_dir/other/websupport.png" "$output_dir/websupport.png"
convert_image_full "$input_dir/other/wiktionary.svg.bin" "$output_dir/wiktionary.png"
convert_image_full "$input_dir/other/www.png" "$output_dir/www.png"

### Combined icons ###

# Ollama with custom background
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/openwebui-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/openwebui-background-mask.png"
magick "$tmpdir/openwebui-background.png" "$tmpdir/openwebui-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/openwebui-background.png"
magick "$tmpdir/openwebui-background.png" -define png:color-type=6 "$tmpdir/openwebui-background.png"
magick -background none -bordercolor transparent "$input_dir/other/openwebui.png" -resize '112x112' -density 1200 "$tmpdir/openwebui-tmp.png"
magick "$tmpdir/openwebui-background.png" "$tmpdir/openwebui-tmp.png" -gravity Center -composite "$tmpdir/openwebui-final.png"
convert_image_full "$tmpdir/openwebui-final.png" "$output_dir/openwebui.png"

# Open WebUI with custom background
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/ollama-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/ollama-background-mask.png"
magick "$tmpdir/ollama-background.png" "$tmpdir/ollama-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/ollama-background.png"
magick "$tmpdir/ollama-background.png" -define png:color-type=6 "$tmpdir/ollama-background.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/ollama.svg" -resize '112x112' -density 1200 "$tmpdir/ollama-tmp.png"
magick "$tmpdir/ollama-background.png" "$tmpdir/ollama-tmp.png" -gravity Center -composite "$tmpdir/ollama-final.png"
convert_image_full "$tmpdir/ollama-final.png" "$output_dir/ollama.png"

# Rounded Squid
magick "$input_dir/other/squid.jpg" \( +clone -alpha extract -draw "fill black roundrectangle 0,0 %[w],%[h] 12,12" -negate \) -alpha off -compose CopyOpacity -composite "$tmpdir/squid.png"
convert_image_full "$tmpdir/squid.png" "$output_dir/squid.png"

# Smtp4dev with custom background
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/smtp4dev-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/smtp4dev-background-mask.png"
magick "$tmpdir/smtp4dev-background.png" "$tmpdir/smtp4dev-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/smtp4dev-background.png"
magick "$tmpdir/smtp4dev-background.png" -define png:color-type=6 "$tmpdir/smtp4dev-background.png"
magick -background none -bordercolor transparent "$input_dir/other/smtp4dev-custom.png" -resize '224x224' -density 1200 "$tmpdir/smtp4dev-tmp.png"
magick "$tmpdir/smtp4dev-background.png" "$tmpdir/smtp4dev-tmp.png" -gravity Center -composite "$tmpdir/smtp4dev-final.png"
convert_image_full "$tmpdir/smtp4dev-final.png" "$output_dir/smtp4dev.png"

# Let's Encrypt with custom background
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/lets-encrypt-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/lets-encrypt-background-mask.png"
magick "$tmpdir/lets-encrypt-background.png" "$tmpdir/lets-encrypt-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/lets-encrypt-background.png"
magick "$tmpdir/lets-encrypt-background.png" -define png:color-type=6 "$tmpdir/lets-encrypt-background.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/lets-encrypt.svg" -resize '224x224' -density 1200 "$tmpdir/lets-encrypt-tmp.png"
magick "$tmpdir/lets-encrypt-background.png" "$tmpdir/lets-encrypt-tmp.png" -gravity Center -composite "$tmpdir/lets-encrypt-final.png"
convert_image_full "$tmpdir/lets-encrypt-final.png" "$output_dir/lets-encrypt.png"

# Multiple servers icon
magick -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_server.svg" -resize "$default_image_size" -border 32 -density 1200 "$tmpdir/server-tmp-1.png"
magick -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_server.svg" -resize 96x96 -border 32 -density 1200 "$tmpdir/server-tmp-2.png"
magick "$tmpdir/server-tmp-1.png" "$tmpdir/server-tmp-2.png" -gravity Center -geometry "$default_image_size+50+80" -composite -resize "$default_image_size" "$tmpdir/servers-tmp.png"
magick "$tmpdir/servers-tmp.png" "$tmpdir/server-tmp-2.png" -gravity Center -geometry "$default_image_size-50+40" -composite -resize "$default_image_size" "$tmpdir/servers-final.png"
convert_image_full "$tmpdir/servers-final.png" "$output_dir/servers.png"

# Combined personal devices icon
magick -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_laptop.svg" -resize "$default_image_size" -border 32 -density 1200 "$tmpdir/laptop-tmp.png"
magick -background none -bordercolor transparent "$tmpdir/13_05_osa_icons_svg/osa_iPhone.svg" -resize 192x192 -border 32 -density 1200 "$tmpdir/phone-tmp.png"
magick "$tmpdir/laptop-tmp.png" "$tmpdir/phone-tmp.png" -gravity Center -geometry "$default_image_size+70+30" -composite -resize "$default_image_size" "$tmpdir/personal-devices-final.png"
convert_image_full "$tmpdir/personal-devices-final.png" "$output_dir/personal-devices.png"

# DWService with custom background
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/dwservice-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/dwservice-background-mask.png"
magick "$tmpdir/dwservice-background.png" "$tmpdir/dwservice-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/dwservice-background.png"
magick "$tmpdir/dwservice-background.png" -define png:color-type=6 "$tmpdir/dwservice-background.png"
magick -background none -bordercolor transparent "$input_dir/other/dwservice.png" -resize '224x224' -density 1200 "$tmpdir/dwservice-tmp.png"
magick "$tmpdir/dwservice-background.png" "$tmpdir/dwservice-tmp.png" -gravity Center -composite "$tmpdir/dwservice-final.png"
convert_image_full "$tmpdir/dwservice-final.png" "$output_dir/dwservice.png"

# Apache prometheus exporter
cp "$input_dir/other/apache.svg.bin" "$tmpdir/apache.svg"
magick -background none -bordercolor transparent "$tmpdir/apache.svg" -resize "$default_image_size" -border 16 "$tmpdir/apache-tmp.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" -resize "$default_image_size" "$tmpdir/prometheus-tmp.png"
magick "$tmpdir/prometheus-tmp.png" "$tmpdir/apache-tmp.png" -gravity Center -geometry "$default_image_size+70+30" -composite -resize "$default_image_size" "$tmpdir/apache-prometheus-exporter-final.png"
convert_image_full "$tmpdir/apache-prometheus-exporter-final.png" "$output_dir/apache-prometheus-exporter.png"

# PiHole prometheus exporter
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" -resize "$default_image_size" -border 96 "$tmpdir/pihole-tmp.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" -resize "$default_image_size" "$tmpdir/prometheus-tmp.png"
magick "$tmpdir/prometheus-tmp.png" "$tmpdir/pihole-tmp.png" -gravity Center -geometry "$default_image_size+75+55" -composite -resize "$default_image_size" "$tmpdir/pihole-prometheus-exporter-final.png"
convert_image_full "$tmpdir/pihole-prometheus-exporter-final.png" "$output_dir/pihole-prometheus-exporter.png"

# Squid prometheus exporter
magick -background none -bordercolor transparent "$output_dir/squid.png" -resize "$default_image_size" -border 160 "$tmpdir/squid-tmp.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" -resize "$default_image_size" "$tmpdir/prometheus-tmp.png"
magick "$tmpdir/prometheus-tmp.png" "$tmpdir/squid-tmp.png" -gravity Center -geometry "$default_image_size+70+70" -composite -resize "$default_image_size" "$tmpdir/squid-prometheus-exporter-final.png"
convert_image_full "$tmpdir/squid-prometheus-exporter-final.png" "$output_dir/squid-prometheus-exporter.png"

### Cleanup ###

rm -rf "$tmpdir"
