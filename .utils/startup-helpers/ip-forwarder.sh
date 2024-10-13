#!/bin/sh
set -euf
# This script sets up macvlan-shim "router" to be able to access containers running in macvlan network from current host

# if [ "$#" -lt 1 ]; then
#     printf 'Not enough arguments\n' >&2
#     exit 1
# fi

router_name="forwarder15"
router_name_2="macvlan-shim"
external_ip="10.1.27.15" # TODO: Can this be in 10.1.17.x range?
external_ip_2="10.1.17.0"
internal_docker_ip="10.1.16.3"

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

sudo ip link add "$router_name" link "$found_interface" type macvlan mode bridge
# sudo ip link add "$router_name" link "$found_interface" type bridge
# sudo ip link add link "$found_interface" name forwarder1 type vlan id 12
sudo ip address add "$external_ip/32" dev "$router_name"
sudo ip link set "$router_name" up

# sudo ip route add "$internal_docker_ip/32" dev "$router_name"
# sudo ip addr add "$external_ip/16" dev "$found_interface"

# sudo iptables -t nat -A PREROUTING -i "$router_name" -d "$external_ip" -j DNAT --to-destination "$internal_docker_ip"
# sudo iptables -t nat -A PREROUTING -i "$router_name_2" -d "$external_ip" -j DNAT --to-destination "$internal_docker_ip"
# sudo iptables -t nat -A POSTROUTING -o "$router_name" -s "$internal_docker_ip" -p tcp --dport 80 -j SNAT --to "$external_ip:80"
# sudo iptables -t nat -A POSTROUTING -o "$router_name_2" -s "$internal_docker_ip" -p tcp --dport 80 -j SNAT --to "$external_ip:80"

sudo iptables -A FORWARD -d "$internal_docker_ip" -i "$router_name" -p tcp -m tcp --dport 80 -j ACCEPT

sudo iptables -t nat -A PREROUTING -d "$external_ip" -p tcp -m tcp --dport 80 -j DNAT --to-destination "$internal_docker_ip"

sudo iptables -t nat -A POSTROUTING -o "$router_name" -j MASQUERADE

# sudo ip addr add "$external_ip_2/32" dev eth0

# sudo iptables -t nat -A PREROUTING -i "$router_name" -s "$external_ip" -d "$external_ip_2" -j DNAT --to-destination "$internal_docker_ip"
# sudo iptables -t nat -A POSTROUTING -o "$router_name_2" -d "$internal_docker_ip" -j MASQUERADE

# sudo iptables -t nat -A PREROUTING -i eth0 -s 10.1.27.3 -d 10.1.16.3 -j DNAT --to-destination 10.1.16.3
# sudo iptables -t nat -A POSTROUTING -o eth0 -d 10.1.16.3 -j MASQUERADE

# sudo ip route add "$internal_docker_ip/32" via "$external_ip" dev eth0
# sudo iptables -A FORWARD -s "$external_ip" -i eth0 -d "$internal_docker_ip" -o eth0 -j ACCEPT

# :3306
# sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination "$internal_docker_ip:443"
# sudo iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source "$external_ip"

# sudo iptables -t nat -A PREROUTING -i eth0 -d "$external_ip" -j DNAT --to-destination "$internal_docker_ip"
# sudo iptables -t nat -A POSTROUTING -j MASQUERADE
# sudo iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source "$external_ip"

# sudo iptables -A FORWARD -i "$router_name" -o "$router_name_2" -j ACCEPT
# sudo iptables -A FORWARD -i "$router_name_2" -o "$router_name" -m state --state ESTABLISHED,RELATED -j ACCEPT
# sudo iptables -t nat -A POSTROUTING -o "$router_name_2" -j MASQUERADE

# iptables -t nat -A PREROUTING -i "$router_name" -j DNAT --to "$internal_docker_ip"
# iptables -t nat -A POSTROUTING -i "$router_name" -s 192.168.1.0/24 -j SNAT --to-source 192.168.42.13
