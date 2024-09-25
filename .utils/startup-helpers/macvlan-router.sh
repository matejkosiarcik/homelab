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

# Get appropriate network interface
has_eth0="$(ip link show eth0 >/dev/null 2>/dev/null || printf '0\n')"
has_enp1s0="$(ip link show enp1s0 >/dev/null 2>/dev/null || printf '0\n')"
found_interface=''
if [ "$has_eth0" = '' ]; then
    found_interface='eth0'
elif [ "$has_enp1s0" = '' ]; then
    found_interface='enp1s0'
fi
if [ "$found_interface" = '' ]; then
    printf 'No suitable network interface found\n'
    exit 1
fi

printf 'Found network interface %s\n' "$found_interface"

# Add macvlan-shim "router" to be able to access containers from host
sudo ip link add "$router_name" link "$found_interface" type macvlan mode bridge
sudo ip addr add "$external_ip/32" dev "$router_name"
sudo ip link set "$router_name" up
sudo ip route add "$internal_docker_ip/32" dev "$router_name"
