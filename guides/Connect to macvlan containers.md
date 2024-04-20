# How to connect to macvlan container from Host?

Unfortunetely you can't connect to container running via macvlan directly from the running Host.
At least not without a special (pricy) network equipment.
You can connect to them from other devices on your network though.

Follow this guide to setup "shim router" which allows the host to connect to these containers as well: https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks/

TL;DR: script

```sh
sudo ip link add macvlan-shim link eth0 type macvlan mode bridge
sudo ip addr add \[shim-ip\]/32 dev macvlan-shim
sudo ip link set macvlan-shim up
sudo ip route add \[containers-ip-range\]/24 dev macvlan-shim
```

TL;DR add to `/etc/network/interfaces.d/macvlan-shim`

```txt
ip link add macvlan-shim link eth0 type macvlan mode bridge
ip addr add \[shim-ip\]/32 dev macvlan-shim
ip link set macvlan-shim up
ip route add \[containers-ip-range\]/24 dev macvlan-shim
```
