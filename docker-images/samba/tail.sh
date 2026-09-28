#!/bin/sh
set -euf

tail -F '/homelab/logs/samba/smbd.log' >>'/homelab/logs/samba/smbd.log2'
