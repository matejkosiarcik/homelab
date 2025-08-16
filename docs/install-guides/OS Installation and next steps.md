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

Copy `homelab` public key to server, disable password authentication, enable key authentication.

On client:

```sh
ssh-copy-id -i ~/.ssh/id_homelab.pub homelab@10.1.4.[host]
```

On server:

```sh
sudo nano /etc/ssh/sshd_config # Set: "PasswordAuthentication no"
sudo service ssh restart
```

## Postinstall - Enable passwordless sudo

On server:

```sh
sudo visudo
# Set following line: homelab ALL=(ALL) NOPASSWD: ALL
```

## Postinstall - Increase inotify limit

On server:

```sh
printf '\nfs.file-max = 65536\nfs.inotify.max_user_instances = 65536\n' | sudo tee '/etc/sysctl.conf'
```

## Postinstall - Docker memory monitoring

Only for ARM devices (Raspberry Pi)!

Add following entries to `/boot/firmware/cmdline.txt` to enable reading how much memory Docker container use:

```txt
cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
```

Then `reboot`.

## Postinstall - Run Ansible

On client:

```sh
ansible-playbook --limit [machine-name] playbooks/setup-server.yml
```

## Postinstall - Login to vaultwarden

On server:

```sh
bw login homelab@vaultwarden.matejhome.com
nano ~/.bashrc
# Paste BW_SESSION=...
```

## Postinstall - Deploy homelab

On server:

```sh
cd "$HOME/git/homelab/servers/.current"
task install
sudo reboot
```

Again, on server:

```sh
cd "$HOME/git/homelab/servers/.current"
task secrets
task deploy
```
