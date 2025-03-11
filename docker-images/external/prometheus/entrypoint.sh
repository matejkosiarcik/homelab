#!/bin/sh
set -euf

tmpfile="$(mktemp)"
sed "s~\${PROMETHEUS_ADMIN_PASSWORD_ENCRYPTED}~$(printf '%s' "$PROMETHEUS_ADMIN_PASSWORD_ENCRYPTED" | base64 -d)~g" </etc/prometheus/web.yml >"$tmpfile"
cat <"$tmpfile" >/etc/prometheus/web.yml
cat /etc/prometheus/web.yml
rm -f "$tmpfile"

prometheus --config.file=/etc/prometheus/prometheus.yml --web.config.file=/etc/prometheus/web.yml
