# RPi OS install with all bells and whistles

## Install OS

### Raspberry Pi

Install OS via RaspberryPi Imager

- GitHub: <https://github.com/raspberrypi/rpi-imager>
- Blogpost: <https://www.raspberrypi.com/news/raspberry-pi-imager-imaging-utility>
- TL;DR: `brew install --cask raspberry-pi-imager`

Notes for installation:

- Set _homelab_ public SSH key
- Set custom hostname
- Disable SSH authentication via password
- Disable Wi-Fi
- Set Timezone _Europe/Bratislava_
- Set username to _matej_

## Other

TBD

## Postinstall - Prepare system for ansible

Install `python3` in order to be able to run ansible on this machine:

TL;DR:

```sh
sudo apt-get update
sudo apt-get install --yes python3
```

## Postinstall - Run ansible setup

TL;DR:

```sh
cd "$(git rev-parse --show-toplevel)/ansible"
. ./venv/bin/activate
ansible-playbook --limit <machine-name> playbooks/setup-system.yml
```

## Postinstall - Slow docker

Sometimes docker can cause issues when starting too fast when network interfaces are not available.
To prevent this, run the following command:

```sh
sudo systemctl edit docker.service
``

And save following content:

```txt
[Service]
ExecStartPre=/bin/sleep 30
```

## Postinstall - Deploy homelab

TL;DR:

```sh
cd "$(git rev-parse --show-toplevel)/ansible"
. ./venv/bin/activate
ansible-playbook --limit <machine-name> playbooks/deploy-homelab-initial.yml
```

## Postinstall - Docker memory

Only for ARM devices (Raspberry Pi)!

Add following entries to `/boot/firmware/cmdline.txt` to enable reading how much memory docker container use:

```txt
cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
```
