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

Run the installation...

## Postinstall - Prepare crucial packages

Install `openssh-server` in order to be able to connect to this machine via SSH.
Install `python3` in order to be able to run ansible on this machine.

TL;DR:

```sh
sudo apt-get update && sudo apt-get install --yes openssh-server python3
```

## Postinstall - Setup SSH

Copy `homelab` public key to server, disable password authentication, enable key authentication.

TL;DR:

```sh
ssh-copy-id -i ~/.ssh/id_homelab.pub homelab@10.1.4.[host]
```

```sh
sudo nano /etc/ssh/sshd_config
# Set following line: PasswordAuthentication no
sudo service ssh restart
```

## Postinstall - Enable passwordless sudo

TL;DR:

```sh
sudo visudo
# Set following line: homelab ALL=(ALL) NOPASSWD: ALL
```

## Postinstall - Run ansible setup

TL;DR:

```sh
ansible-playbook --limit [machine-name] playbooks/setup-server.yml
```

## Postinstall - Login to vaultwarden

TL;DR

```sh
bw login homelab@vaultwarden.matejhome.com
nano ~/.bashrc
# Paste BW_SESSION=...
```

## Postinstall - Deploy homelab

TL;DR:

```sh
cd "$HOME/git/homelab/servers/.current"
sh main.sh install --prod
sudo reboot
cd "$HOME/git/homelab/servers/.current"
sh main.sh secrets --prod
sh main.sh deploy --prod
```

## Postinstall - Docker memory monitoring

Only for ARM devices (Raspberry Pi)!

Add following entries to `/boot/firmware/cmdline.txt` to enable reading how much memory docker container use:

```txt
cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
```
