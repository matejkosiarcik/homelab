#!/bin/sh
router_name=foo
found_interface=eth0
external_ip=10.1.100.3

# Add macvlan-shim "router" to be able to access containers from host
sudo ip link add "$router_name" link "$found_interface" type macvlan mode bridge
sudo ip addr add "$external_ip/24" dev "$router_name"
sudo ip link set "$router_name" up
# sudo ip route add "$internal_docker_ip/24" dev "$router_name"

WANIF='eth0.26'
LANIF='foo'

# enable ip forwarding in the kernel
echo 'Enabling Kernel IP forwarding...'
/bin/echo 1 > /proc/sys/net/ipv4/ip_forward

# flush rules and delete chains
echo 'Flushing rules and deleting existing chains...'
sudo iptables -F
sudo iptables -X

# enable masquerading to allow LAN internet access
echo 'Enabling IP Masquerading and other rules...'
sudo iptables -t nat -A POSTROUTING -o $LANIF -j MASQUERADE
sudo iptables -A FORWARD -i $LANIF -o $WANIF -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $WANIF -o $LANIF -j ACCEPT

sudo iptables -t nat -A POSTROUTING -o $WANIF -j MASQUERADE
sudo iptables -A FORWARD -i $WANIF -o $LANIF -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $LANIF -o $WANIF -j ACCEPT

echo 'Done.'
