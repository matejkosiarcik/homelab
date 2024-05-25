#!/bin/sh
set -euf

socat TCP4-LISTEN:80,fork,reuseaddr TCP4:pihole-http-proxy:80 &
socat TCP4-LISTEN:443,fork,reuseaddr TCP4:pihole-http-proxy:443 &
socat TCP4-LISTEN:53,fork,reuseaddr TCP4:pihole-app:53 &
socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:pihole-app:53 &
