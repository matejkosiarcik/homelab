#!/bin/sh
set -euf

node "/app/dist/$HOMELAB_APP_TYPE/$HOMELAB_AUTOMATION_TYPE.js"
