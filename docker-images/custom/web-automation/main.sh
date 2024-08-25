#!/bin/sh
set -euf

node "/app/dist/$HOMELAB_APP_NAME/$HOMELAB_CONTAINER_VARIANT.js"
