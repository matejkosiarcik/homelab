#!/bin/sh
set -euf

# git_dir="$(cd "$(dirname "$(realpath "$0")")" >/dev/null 2>&1 && git rev-parse --show-toplevel)"
git_dir="$HOME/git/homelab"

sh "$git_dir/.utils/startup-helpers/disable-swap.sh"
sh "$git_dir/.utils/startup-helpers/rfkill.sh"

seq 1 3 | while read -r index; do
    sh "$git_dir/.utils/startup-helpers/macvlan-router.sh" "macvlan-$(printf '%03d' "$index")" "10.1.17.$index" "10.1.16.$index"
done

# router_name="macvlan"
# external_ip="10.1.17.0"
# internal_docker_ip="10.1.16.0"

# # Get appropriate network interface
# has_eth0="$(ip link show eth0 >/dev/null 2>/dev/null || printf '0\n')"
# has_enp1s0="$(ip link show enp1s0 >/dev/null 2>/dev/null || printf '0\n')"
# found_interface=''
# if [ "$has_eth0" = '' ]; then
#     found_interface='eth0'
# elif [ "$has_enp1s0" = '' ]; then
#     found_interface='enp1s0'
# fi
# if [ "$found_interface" = '' ]; then
#     printf 'No suitable network interface found\n'
#     exit 1
# fi

# printf 'Found network interface %s\n' "$found_interface"

# printf 'Creating new router %s with IP %s for network %s\n' "$router_name" "$external_ip" "$internal_docker_ip"

# # Add macvlan-shim "router" to be able to access containers from host
# sudo ip link add "$router_name" link "$found_interface" type macvlan mode bridge
# sudo ip addr add "$external_ip/24" dev "$router_name"
# sudo ip link set "$router_name" up
# sudo ip route add "$internal_docker_ip/24" dev "$router_name"
