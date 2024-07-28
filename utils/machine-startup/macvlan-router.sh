#!/bin/sh
set -euf
# This script sets up macvlan-shim "router" to be able to access containers running in macvlan network from current host

if [ "$#" -lt 2 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

router_name="$1"
external_ip="$2"
internal_docker_ip="$3"

# Add macvlan-shim "router" to be able to access containers from host
sudo ip link add "$router_name" link eth0 type macvlan mode bridge
sudo ip addr add "$external_ip/32" dev "$router_name"
sudo ip link set "$router_name" up
sudo ip route add "$internal_docker_ip/32" dev "$router_name"
