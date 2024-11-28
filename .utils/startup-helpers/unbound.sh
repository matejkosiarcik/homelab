#!/bin/sh
set -euf
# This script starts native unbound

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

config_file="$1"
# nohup sudo unbound -c "$config_file" &
sudo unbound -d -v -c "$config_file"
