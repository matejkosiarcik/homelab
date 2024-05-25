#!/bin/sh
set -euf

# Disable swap (should prolong SD card life)
sudo swapoff -a

# Add macvlan-shim "router" to be able to access containers from host
sudo ip link add macvlan-shim link eth0 type macvlan mode bridge
sudo ip addr add 10.1.6.2/32 dev macvlan-shim
sudo ip link set macvlan-shim up
sudo ip route add 10.1.12.0/24 dev macvlan-shim
