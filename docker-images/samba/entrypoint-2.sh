#!/bin/sh
set -euf

# Samba has 2 stage entrypoint
# This is 2nd stage, which runs under user "homelab"

# sleep 1

# sleep Infinity
exec smbd --foreground --no-process-group --configfile='/homelab/tmpfs/smb.conf'
