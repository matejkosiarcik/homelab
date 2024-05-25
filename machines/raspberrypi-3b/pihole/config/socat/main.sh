#!/bin/sh
set -euf

socat TCP4-LISTEN:80,fork,reuseaddr TCP4:10.1.10.3:80 &
socat TCP4-LISTEN:443,fork,reuseaddr TCP4:10.1.10.3:443 &
socat TCP4-LISTEN:53,fork,reuseaddr TCP4:10.1.10.2:53 &
socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:10.1.10.2:53 &
