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
output_dir="$(git rev-parse --show-toplevel)/docker-images/external/homepage/icons"
rm -rf "$output_dir"
mkdir -p "$output_dir"

tmpdir=''
# shellcheck source=/dev/null
. "$(dirname "$0")/.build-utils.sh"

# shellcheck disable=SC2034
default_image_size='128x128'
# shellcheck disable=SC2034
default_convert_options='magick -background none -bordercolor transparent INPUT_FILE -resize 126x126 -density 1200 -border 1 OUTPUT_FILE'

### Dashboard Icons ###

convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/dawarich.svg" "$output_dir/dawarich.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/files.svg" "$output_dir/files.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/gitea.svg" "$output_dir/gitea.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/gitlab.png" "$output_dir/gitlab.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/glances.svg" "$output_dir/glances.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/gotify.svg" "$output_dir/gotify.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/grafana.svg" "$output_dir/grafana.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/graylog.svg" "$output_dir/graylog.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/homepage.png" "$output_dir/homepage.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/immich.svg" "$output_dir/immich.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/jenkins.svg" "$output_dir/jenkins.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/loki.svg" "$output_dir/loki.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/netalertx.png" "$output_dir/netalertx.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/netdata.svg" "$output_dir/netdata.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/nextcloud.svg" "$output_dir/nextcloud.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/ntfy.svg" "$output_dir/ntfy.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/openspeedtest.png" "$output_dir/openspeedtest.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/owncloud.svg" "$output_dir/owncloud.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/owntracks.svg" "$output_dir/owntracks.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/png/pi-alert.png" "$output_dir/pialert.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/portainer.svg" "$output_dir/portainer.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/samba-server.svg" "$output_dir/samba.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/specifically-clementines.svg" "$output_dir/specifically-clementines.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/unbound.svg" "$output_dir/unbound.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/vaultwarden-light.svg" "$output_dir/vaultwarden.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/vikunja.svg" "$output_dir/vikunja.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/wikipedia-light.svg" "$output_dir/wikipedia.png"
convert_image_full "$input_dir/gitman-repositories/dashboard-icons/svg/zabbix.svg" "$output_dir/zabbix.png"

### Homer icons ###

convert_image_full "$input_dir/gitman-repositories/homer-icons/png/apple-retro.png" "$output_dir/apple.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/cadvisor.png" "$output_dir/cadvisor.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/changedetection.png" "$output_dir/changedetection.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/docker-moby.png" "$output_dir/docker.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/dozzle.png" "$output_dir/dozzle.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/filebrowser.svg" "$output_dir/filebrowser.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/jellyfin.svg" "$output_dir/jellyfin.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/minio.png" "$output_dir/minio.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/motioneye.png" "$output_dir/motioneye.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/prometheus.svg" "$output_dir/prometheus.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/omada.png" "$output_dir/tp-link-omada.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/tp-link.png" "$output_dir/tp-link.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/png/tvheadend.png" "$output_dir/tvheadend.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/ubiquiti.svg" "$output_dir/unifi.png"
convert_image_full "$input_dir/gitman-repositories/homer-icons/svg/uptime-kuma.svg" "$output_dir/uptimekuma.png"

### Kubernetes Icons ###

convert_image_full "$input_dir/gitman-repositories/kubernetes-community/icons/svg/resources/unlabeled/ns.svg" "$output_dir/placeholder.png"

### Organizr Icons ###

convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/healthchecks.png" "$output_dir/healthchecks.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/homeassistant.png" "$output_dir/homeassistant.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/pihole.png" "$output_dir/pihole.png"
convert_image_full "$input_dir/gitman-repositories/organizr/plugins/images/tabs/speedtest-icon.png" "$output_dir/speedtest.png"

### OSA Icons ###

convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_awareness.svg" "$output_dir/lightbulb.png"
convert_image_full "$tmpdir/13_05_osa_icons_svg/osa_wireless_network.svg" "$output_dir/wifi-ap.png"

### VRT Icons ###

convert_image_full "$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Router.svg" "$output_dir/router.png"
convert_image_full "$input_dir/gitman-repositories/dia-vrt-sheets/SVG/VRT Networking & Communications/Switch 2.svg" "$output_dir/switch.png"

### Other Icons ###

convert_image_full "$input_dir/other/actualbudget.png" "$output_dir/actualbudget.png"
convert_image_full "$input_dir/other/antennas.png" "$output_dir/antennas.png"
convert_image_full "$input_dir/other/automatic1111.png" "$output_dir/automatic1111.png"
convert_image_full "$input_dir/other/gatus.png" "$output_dir/gatus.png"
convert_image_full "$input_dir/other/odroid.png" "$output_dir/odroid.png"
convert_image_full "$input_dir/other/raspberry-pi.svg.bin" "$output_dir/raspberry-pi.png"
convert_image_full "$input_dir/other/smtp4dev-custom.png" "$output_dir/smtp4dev.png"
convert_image_full "$input_dir/other/squid.jpg" "$output_dir/squid.jpg"
convert_image_full "$input_dir/other/upc.svg.bin" "$output_dir/upc.png"
convert_image_full "$input_dir/other/wiktionary.svg.bin" "$output_dir/wiktionary.png"

### Combined icons ###

# Let's Encrypt with custom background
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/lets-encrypt-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/lets-encrypt-background-mask.png"
magick "$tmpdir/lets-encrypt-background.png" "$tmpdir/lets-encrypt-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/lets-encrypt-background.png"
magick "$tmpdir/lets-encrypt-background.png" -define png:color-type=6 "$tmpdir/lets-encrypt-background.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/lets-encrypt.svg" -resize '112x112' -density 1200 "$tmpdir/lets-encrypt-tmp.png"
magick "$tmpdir/lets-encrypt-background.png" "$tmpdir/lets-encrypt-tmp.png" -gravity Center -composite "$tmpdir/lets-encrypt-final.png"
convert_image_full "$tmpdir/lets-encrypt-final.png" "$output_dir/lets-encrypt.png"

# Ollama with custom background
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/ollama-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/ollama-background-mask.png"
magick "$tmpdir/ollama-background.png" "$tmpdir/ollama-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/ollama-background.png"
magick "$tmpdir/ollama-background.png" -define png:color-type=6 "$tmpdir/ollama-background.png"
magick -background none -bordercolor transparent "$input_dir/gitman-repositories/dashboard-icons/svg/ollama.svg" -resize '112x112' -density 1200 "$tmpdir/ollama-tmp.png"
magick "$tmpdir/ollama-background.png" "$tmpdir/ollama-tmp.png" -gravity Center -composite "$tmpdir/ollama-final.png"
convert_image_full "$tmpdir/ollama-final.png" "$output_dir/ollama.png"

# Open WebUI with custom background
magick -size "$default_image_size" xc:#ffffffef "$tmpdir/openwebui-background.png"
magick -size "$default_image_size" xc:black -fill white -draw "roundRectangle 0,0,$(printf '%s' "$default_image_size" | tr 'x' ',') 16,16" "$tmpdir/openwebui-background-mask.png"
magick "$tmpdir/openwebui-background.png" "$tmpdir/openwebui-background-mask.png" -alpha Off -compose CopyOpacity -composite "$tmpdir/openwebui-background.png"
magick "$tmpdir/openwebui-background.png" -define png:color-type=6 "$tmpdir/openwebui-background.png"
magick -background none -bordercolor transparent "$input_dir/other/openwebui.png" -resize '112x112' -density 1200 "$tmpdir/openwebui-tmp.png"
magick "$tmpdir/openwebui-background.png" "$tmpdir/openwebui-tmp.png" -gravity Center -composite "$tmpdir/openwebui-final.png"
convert_image_full "$tmpdir/openwebui-final.png" "$output_dir/openwebui.png"

### Cleanup ###

rm -rf "$tmpdir"
