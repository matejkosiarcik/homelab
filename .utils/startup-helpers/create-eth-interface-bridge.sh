#!/bin/sh
set -euf
# This script sets up macvlan-shim "router" to be able to access containers running in macvlan network from current host

if [ "$#" -lt 2 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

id="$1"
external_ip="$2"

# Get appropriate network interface
found_interface=''
if [ "$found_interface" = '' ]; then
    found_interface="$(((ip link show eth0 >/dev/null 2>/dev/null) && printf 'eth0') || true)"
fi
if [ "$found_interface" = '' ]; then
    found_interface="$(((ip link show enp1s0 >/dev/null 2>/dev/null) && printf 'enp1s0') || true)"
fi
if [ "$found_interface" = '' ]; then
    found_interface="$(((ip link show enp1s0f0 >/dev/null 2>/dev/null) && printf 'enp1s0f0') || true)"
fi

if [ "$found_interface" = '' ]; then
    printf 'No suitable network interface found\n'
    exit 1
fi

# printf 'Found network interface %s\n' "$found_interface"

router_name="ethbr-$id"
sudo ip link add link "$found_interface" name "$router_name" type bridge
sudo ip address add "$external_ip/32" dev "$router_name"
sudo ip link set "$router_name" up
