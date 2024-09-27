#!/bin/sh
set -euf

if [ "$CRON" != '1' ]; then
    printf '%s - Skipping initial run\n' "$(date '+%Y-%m-%d_%H-%M-%S')"
    exit
fi

printf '%s - Starting %s for %s\n' "$(date '+%Y-%m-%d_%H-%M-%S')" "$HOMELAB_CONTAINER_VARIANT" "$HOMELAB_APP_NAME"
node "/homelab/dist/$HOMELAB_APP_NAME/$HOMELAB_CONTAINER_VARIANT.js"
printf '%s - Finished %s for %s\n' "$(date '+%Y-%m-%d_%H-%M-%S')" "$HOMELAB_CONTAINER_VARIANT" "$HOMELAB_APP_NAME"
