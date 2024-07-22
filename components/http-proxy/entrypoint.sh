#!/bin/sh
set -euf

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'certificate\.crt' '/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates\n" && apachectl -k restart' - &
# TODO: consider "ts '%Y-%m-%d %H:%M:%.S |'"

# Start apache
apachectl -D FOREGROUND
