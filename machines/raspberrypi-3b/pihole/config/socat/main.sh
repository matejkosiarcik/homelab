#!/bin/sh
set -euf

# socat TCP-LISTEN:80,fork,reuseaddr TCP:pihole-http-proxy:80 &
# socat TCP-LISTEN:443,fork,reuseaddr TCP:pihole-http-proxy:443 &
# socat TCP-LISTEN:53,fork,reuseaddr TCP:pihole-app:53 &
# socat UDP-LISTEN:53,fork,reuseaddr UDP:pihole-app:53 &

socat TCP-LISTEN:80,fork,reuseaddr TCP:10.1.10.3:80 &
socat TCP-LISTEN:443,fork,reuseaddr TCP:10.1.10.3:443 &
socat TCP-LISTEN:53,fork,reuseaddr TCP:10.1.10.2:53 &
socat UDP-LISTEN:53,fork,reuseaddr UDP:10.1.10.2:53 &
