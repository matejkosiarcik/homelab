#!/bin/sh
set -euf

# sleep 1

sudo ip link add macvlan-shim link eth0 type macvlan mode bridge
sudo ip addr add 10.1.6.2/32 dev macvlan-shim
sudo ip link set macvlan-shim up
sudo ip route add 10.1.10.0/24 dev macvlan-shim
