# How to connect to macvlan container from Host?

Unfortunetely you can't connect to container running via macvlan directly from the running Host.
At least not without a special (pricy) network equipment.
You can connect to them from other devices on your network though.

Follow this guide to setup "shim router" which allows the host to connect to these containers as well: https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks/

Here is the main script:

```sh
sudo ip link add macvlan-shim link eth0 type macvlan mode bridge
sudo ip addr add \[shim-ip\]/32 dev macvlan-shim
sudo ip link set macvlan-shim up
sudo ip route add \[containers-ip-range\]/24 dev macvlan-shim
```

Where `[shim-ip]` is the interface address (from `10.1.6.x` address space) and `[containers-ip-range]` is the entire subnet where macvlan containers have assigned IP address.

Problem is these settings do not persist between PC reboots.
To make it persistant:

```sh
crontab -e

# Add following entry:
@reboot sh "$HOME/git/homelab/machines/<machine-name>/startup.sh"
```
