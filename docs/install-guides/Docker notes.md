# Install Docker

- Instructions general: <https://docs.docker.com/engine/install/debian>
- Instructions for Raspberry Pi \(32bit only\): <https://docs.docker.com/engine/install/raspberry-pi-os>

## How to connect to macvlan container from Host

Unfortunetely you can't connect to container running via macvlan directly from the running Host.
At least not without a special (pricy) network equipment.
You can connect to them from other devices on your network though.

Additionally, macvlan networks require their gateway to be unique, so you can't use the same gateway (eg. the main physical network gateway) from 2 independent macvlan networks.
This can also be workaround by having a virtual router, which is created on system startup and is unique to each macvlan network.

Follow this guide to setup "shim router" which allows the host to connect to these containers as well: <https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks>

This script is already setup in `startup.sh` script.
