#!/bin/sh
set -euf

exec ncp --listen 0.0.0.0:8080 --redis-address 'redis:6379' --redis-password "${REDIS_PASSWORD}"
