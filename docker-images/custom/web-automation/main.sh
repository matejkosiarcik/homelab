#!/bin/sh
set -euf

printf '%s - Starting %s for %s\n' "$(date '+%Y-%m-%d_%H-%M-%S')" "$HOMELAB_CONTAINER_VARIANT" "$HOMELAB_APP_NAME"
node "/app/dist/$HOMELAB_APP_NAME/$HOMELAB_CONTAINER_VARIANT.js"
printf '%s - Finished %s for %s\n' "$(date '+%Y-%m-%d_%H-%M-%S')" "$HOMELAB_CONTAINER_VARIANT" "$HOMELAB_APP_NAME"
