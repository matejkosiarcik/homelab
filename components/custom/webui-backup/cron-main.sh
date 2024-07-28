#!/bin/sh
set -euf

PATH="$PATH:/usr/local/bin"
# shellcheck source=/dev/null
. /app/.internal/cron.env

node "/app/dist/$HOMELAB_SERVICE.js"
