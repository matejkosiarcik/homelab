#!/bin/sh
set -euf

# Start server
sh '/homelab/main.sh'

# Setup monitoring and restart server when ZIM files change
inotifywait --monitor --recursive --event attrib,close_write,create,delete,modify,move --format '%w%f' '/data' | xargs -n1 sh '/homelab/main.sh' &

# Wait forever
while true; do
    sleep infinity
done
