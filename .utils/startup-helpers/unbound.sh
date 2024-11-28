#!/bin/sh
set -euf
# This script starts native unbound

if [ "$#" -lt 2 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

config_file="$1"
log_file="$2"

sudo rm -f "$log_file"
sudo touch "$log_file"
sudo chown root:root "$log_file"

nohup sudo unbound -v -c "$config_file" &
