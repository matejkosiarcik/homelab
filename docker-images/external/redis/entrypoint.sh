#!/bin/sh
set -euf

# Resolve placeholders in config
cat /homelab/redis.conf |
    sed "s~\${REDIS_PASSWORD}~${REDIS_PASSWORD}~g" \
    >/homelab/tmpfs/redis.conf

# Start
redis-server /homelab/tmpfs/redis.conf
