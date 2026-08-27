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
- Set username to _homelab_

## Other

Notes for installation:

- Set custom hostname (same as server-name)
- Set Timezone _Europe/Bratislava_
- Set username to _homelab_
- Do not set root password

## Postinstall - Prepare essential packages

Install `openssh-server` in order to be able to connect to this machine via SSH.
Install `python3` in order to be able to run Ansible on this machine.

On server:

```sh
sudo apt-get update && sudo apt-get install --yes openssh-server python3
```

## Postinstall - Setup SSH

Copy `homelab` public key to server:

On client:

```sh
ssh-copy-id -i ~/.ssh/id_homelab.pub homelab@server-<name>.matejhome.com
```

## Postinstall - Enable passwordless sudo

On server:

```sh
sudo visudo
# Set following line: homelab ALL=(ALL) NOPASSWD: ALL
```

## Postinstall - Run Ansible

On client:

```sh
ansible-playbook --limit <server-name> playbooks/setup-server.yml
```
