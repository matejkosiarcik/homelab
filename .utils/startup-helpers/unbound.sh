#!/bin/sh
set -euf
# This script starts native unbound

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

config_file="$1"
log_file="/root/.log/unbound/$(basename "$config_file" .conf).log"

sudo mkdir -p "$(dirname "$log_file")"
sudo rm -f "$log_file"
sudo touch "$log_file"
sudo chown root:root "$log_file"
sudo chmod a+rw "$log_file"

sudo touch "/root/config/unbound/$(basename "$config_file" .conf).sock"
sudo chown root:root "/root/config/unbound/$(basename "$config_file" .conf).sock"
sudo chmod a+rwx "/root/config/unbound/$(basename "$config_file" .conf).sock"

sudo unbound -v -c "/root/config/unbound/$(basename "$config_file")" &
