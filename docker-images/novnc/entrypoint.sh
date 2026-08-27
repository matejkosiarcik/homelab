#!/bin/sh
set -euf

# Copy files to real "/homelab/noVNC/app"
mkdir -p /homelab/noVNC/app
cp -R /homelab/original/noVNC/app/. /homelab/noVNC/app

bash -c "/homelab/noVNC/utils/novnc_proxy --vnc ${VNC_SERVER}"
