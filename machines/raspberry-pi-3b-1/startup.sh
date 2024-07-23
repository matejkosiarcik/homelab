#!/bin/sh
set -euf

git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"

sh "$git_dir/.utils/startup/disable-swap.sh"
# sh "$git_dir/.utils/startup/macvlan-router.sh" 10.1.6.4 10.1.10.0
# sh "$git_dir/.utils/startup/macvlan-router.sh" 10.1.6.104 10.1.10.0
# sh "$git_dir/.utils/startup/macvlan-router.sh" 10.1.6.105 10.1.10.0

router_name="macvlan-shim2"
sudo ip link add "$router_name" link eth0 type macvlan mode bridge
sudo ip addr add "10.1.6.104/32" dev "$router_name"
sudo ip link set "$router_name" up
sudo ip route add "10.1.10.0/30" dev "$router_name"

router_name="macvlan-shim3"
sudo ip link add "$router_name" link eth0 type macvlan mode bridge
sudo ip addr add "10.1.6.105/32" dev "$router_name"
sudo ip link set "$router_name" up
sudo ip route add "10.1.10.128/30" dev "$router_name"
