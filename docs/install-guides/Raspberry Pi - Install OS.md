# RPi OS install with all bells and whistles

## Install OS

Install OS via RaspberryPi Imager

- GitHub: <https://github.com/raspberrypi/rpi-imager>
- Blogpost: <https://www.raspberrypi.com/news/raspberry-pi-imager-imaging-utility>
- TL;DR: `brew install --cask raspberry-pi-imager`

Notes:

- Set _homelab_ public SSH key
- Disable hostname
- Disable SSH authentication via password
- Disable WiFi
- Set Timezone _Europe/Bratislava_
- Set username to _matej_

## Base system packages

Update system packages and install other essential packages:

TL;DR:

```sh
sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get install --yes ca-certificates curl dnsutils git rsync wget

# git - homelab gitflow
# ca-certificates - required for TLS and docker
# rsync - required for log2ram
# curl, wget - general HTTPs utilities
# dnsutils - debugging DNS problems
```

## Install Log2Ram

Install _Log2Ram_

- GitHub: <https://github.com/azlux/log2ram>
- Guide: <https://pimylifeup.com/raspberry-pi-log2ram>

TL;DR:

```sh
echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
sudo curl https://azlux.fr/repo.gpg -o /usr/share/keyrings/azlux-archive-keyring.gpg
sudo apt-get update
sudo apt-get install --yes log2ram
sudo reboot

# Verify installation
systemctl status log2ram

# Modify settings (disable email "MAIL=false")
sudo nano /etc/log2ram.conf
# Verify edit
cat /etc/log2ram.conf
```

## Next steps

Continue with guide: "Install docker"
