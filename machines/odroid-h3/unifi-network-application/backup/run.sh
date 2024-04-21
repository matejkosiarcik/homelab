#!/bin/sh
set -euf

# TODO: call healthchecks before (start) and after (success/failure)
# TODO: collect logs (and attach to healthchecks)
node /app/main.js
