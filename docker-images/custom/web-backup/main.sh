#!/bin/sh
set -euf

node "/app/dist/$HOMELAB_APP_TYPE/backup.js"
