#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

printf 'starting\n' >'/homelab/tmpfs/status.txt'

# Wait for target container to start
timeout 30s sh <<EOF
printf '%s [INFO]: Waiting for container %s\n' "\$(date "${datetime_format}")" "${HOMELAB_SETUP_TARGET_CONTAINER}" >&2
while [ "\$(docker ps --quiet --filter "name=^${HOMELAB_SETUP_TARGET_CONTAINER}\\$" --filter 'status=running')" == '' ]; do
    sleep 1
done
printf '%s [INFO]: Container found\n' "\$(date "${datetime_format}")" >&2
EOF

sleep "${HOMELAB_SETUP_DELAY-10}"

printf '%s [INFO]: Starting setup\n' "$(date "${datetime_format}")" >&2
if [ -n "${HOMELAB_SETUP_TARGET_USER-}" ]; then
    docker exec --user "${HOMELAB_SETUP_TARGET_USER}" "${HOMELAB_SETUP_TARGET_CONTAINER}" sh '/homelab/setup.sh'
else
    docker exec "${HOMELAB_SETUP_TARGET_CONTAINER}" sh '/homelab/setup.sh'
fi
printf '%s [INFO]: Finished setup\n' "$(date "${datetime_format}")" >&2

printf 'started\n' >'/homelab/tmpfs/status.txt'
exec sleep infinity
