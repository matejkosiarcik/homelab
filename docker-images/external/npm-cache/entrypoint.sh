#!/bin/sh
set -euf

ncp --listen 0.0.0.0:8080 --redis-address 'redis:6379' --redis-password "${REDIS_PASSWORD}"
