#!/bin/sh
set -euf
# This script starts native unbound

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

config_file="$1"
log_file="/root/.log/$(basename $config_file .conf).log"

mkdir -p "$(dirname "$log_file")"
sudo rm -f "$log_file"
sudo touch "$log_file"
sudo chown root:root "$log_file"
sudo chmod a+rw "$log_file"

nohup sudo unbound -v -c "$config_file" &
