#!/bin/sh
set -euf

if [ ! -f /homelab/sock/unbound.sock ]; then
    touch /homelab/sock/unbound.sock
fi

unbound_exporter -unbound.host unix:///homelab/sock/unbound.sock
