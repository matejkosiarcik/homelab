#!/bin/sh
set -euf
# This script sets up macvlan-shim "router" to be able to access containers running in macvlan network from current host

if [ "$#" -lt 2 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

current_external_ip="$1"
new_macvlan_ip_range="$2"

# Add macvlan-shim "router" to be able to access containers from host
sudo ip link add macvlan-shim link eth0 type macvlan mode bridge
sudo ip addr add "$current_external_ip/32" dev macvlan-shim
sudo ip link set macvlan-shim up
sudo ip route add "$new_macvlan_ip_range/24" dev macvlan-shim
