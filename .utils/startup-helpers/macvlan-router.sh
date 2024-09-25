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

interface_is_found='0'
found_interface="$(
    sh <<EOF
    printf 'eth0\nenp1s0\n' | while read -r potential_interface; do
        interface_is_found='1'
        ip link show "$potential_interface" >/dev/null 2>/dev/null || interface_is_found='0'
        if [ "$interface_is_found" -eq 1 ]; then
            printf '%s\n' "$potential_interface"
            break
        fi
    done
EOF
)"

printf 'Found network interface %s\n' "$found_interface"

# Add macvlan-shim "router" to be able to access containers from host
sudo ip link add "$router_name" link "$found_interface" type macvlan mode bridge
sudo ip addr add "$external_ip/32" dev "$router_name"
sudo ip link set "$router_name" up
sudo ip route add "$internal_docker_ip/32" dev "$router_name"
