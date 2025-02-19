#!/bin/sh
set -euf
# This script starts native unbound

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

config_file="$1"

log_file="/homelab/log/unbound/$(basename "$config_file" .conf).log"
sudo rm -f "$log_file"
sudo touch "$log_file"
sudo chown root:root "$log_file" # TODO: Remove permissions after homelab user is created
sudo chmod a+rw "$log_file" # TODO: Remove permissions after homelab user is created

socket_file="/homelab/config/unbound/$(basename "$config_file" .conf).sock"
sudo rm -f "$log_file"
sudo touch "$socket_file"
sudo chown root:root "$socket_file" # TODO: Remove permissions after homelab user is created
sudo chmod a+rwx "$socket_file" # TODO: Remove permissions after homelab user is created

sudo unbound -v -c "/homelab/config/unbound/$(basename "$config_file")" &
