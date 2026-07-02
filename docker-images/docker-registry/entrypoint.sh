#!/bin/sh
set -euf

# Resolve placeholders in config
cat </homelab/config.yml |
    sed "s~\${REDIS_PASSWORD}~${REDIS_PASSWORD}~g" \
        >/homelab/tmpfs/config.yml

# Start
registry serve /homelab/tmpfs/config.yml
