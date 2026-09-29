#!/bin/sh
set -euf

/usr/share/novnc/utils/novnc_proxy --listen '0.0.0.0:6080' --vnc "${VNC_SERVER}" --file-only --web-auth --auth-plugin 'BasicHTTPAuth' --auth-source "${WEB_AUTH_USERNAME}:${WEB_AUTH_PASSWORD}"
