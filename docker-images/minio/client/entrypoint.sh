#!/bin/sh
set -euf

printf 'starting\n' >'/homelab/tmpfs/status.txt'

sh '/homelab/main.sh'

printf 'started\n' >'/homelab/tmpfs/status.txt'
exec sleep infinity
