#!/bin/sh
set -euf

tmpfile="$(mktemp)"
sed "s~\${PROMETHEUS_ADMIN_PASSWORD_ENCRYPTED}~$(printf '%s' "$PROMETHEUS_ADMIN_PASSWORD_ENCRYPTED" | base64 -d)~g" </etc/prometheus/web.yml >"$tmpfile"
cat <"$tmpfile" >/etc/prometheus/web.yml
sed "s~\${GATUS_1_PASSWORD}~$GATUS_1_PASSWORD~g;s~\${GATUS_2_PASSWORD}~$GATUS_2_PASSWORD~g;s~\${GLANCES_ODROID_H3_PASSWORD}~$GLANCES_ODROID_H3_PASSWORD~g;s~\${GLANCES_RASPBERRY_PI_3B_PASSWORD}~$GLANCES_RASPBERRY_PI_3B_PASSWORD~g;s~\${GLANCES_RASPBERRY_PI_4B_2G_PASSWORD}~$GLANCES_RASPBERRY_PI_4B_2G_PASSWORD~g;s~\${GLANCES_RASPBERRY_PI_4B_4G_PASSWORD}~$GLANCES_RASPBERRY_PI_4B_4G_PASSWORD~g;s~\${HOMEASSISTANT_TOKEN}~$HOMEASSISTANT_TOKEN~g;s~\${MINIO_TOKEN}~$MINIO_TOKEN~g;s~\${PIHOLE_1_PRIMARY_PASSWORD}~$PIHOLE_1_PRIMARY_PASSWORD~g;s~\${PIHOLE_1_SECONDARY_PASSWORD}~$PIHOLE_1_SECONDARY_PASSWORD~g;s~\${PIHOLE_2_PRIMARY_PASSWORD}~$PIHOLE_2_PRIMARY_PASSWORD~g;s~\${PIHOLE_2_SECONDARY_PASSWORD}~$PIHOLE_2_SECONDARY_PASSWORD~g" </etc/prometheus/prometheus.yml >"$tmpfile"
cat <"$tmpfile" >/etc/prometheus/prometheus.yml
rm -f "$tmpfile"

promtool check web-config /etc/prometheus/web.yml
promtool check config /etc/prometheus/prometheus.yml

prometheus --config.file=/etc/prometheus/prometheus.yml --web.config.file=/etc/prometheus/web.yml
