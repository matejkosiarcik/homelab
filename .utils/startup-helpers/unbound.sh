#!/bin/sh
set -euf
# This script starts native unbound

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

sudo mkdir -p /root/config/unbound /root/.log/unbound

config_file="$1"

log_file="/root/.log/unbound/$(basename "$config_file" .conf).log"
sudo mkdir -p "$(dirname "$log_file")"
sudo rm -f "$log_file"
sudo touch "$log_file"
sudo chown root:root "$log_file"
sudo chmod a+rw "$log_file"

socket_file="/root/config/unbound/$(basename "$config_file" .conf).sock"
sudo touch "$socket_file"
sudo chown root:root "$socket_file"
sudo chmod a+rwx "$socket_file"

sudo unbound -v -c "/root/config/unbound/$(basename "$config_file")" &
