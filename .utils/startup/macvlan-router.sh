#!/bin/sh
set -euf
# This script sets up macvlan-shim "router" to be able to access containers running in macvlan network from current host

if [ "$#" -lt 2 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

current_external_ip="$1"
new_macvlan_ip_range="$2"

router_name="macvlan-shim-$(printf '%s' "$current_external_ip" | tr '.' '-')"

# Add macvlan-shim "router" to be able to access containers from host
sudo ip link add "$router_name" link eth0 type macvlan mode bridge
sudo ip addr add "$current_external_ip/32" dev "$router_name"
sudo ip link set "$router_name" up
sudo ip route add "$new_macvlan_ip_range/24" dev "$router_name"
