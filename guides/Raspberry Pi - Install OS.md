# RPi OS install with all bells and whistles

## Install OS

Install OS via RaspberryPi Imager

- GitHub: <https://github.com/raspberrypi/rpi-imager>
- Blogpost: <https://www.raspberrypi.com/news/raspberry-pi-imager-imaging-utility>
- TL;DR: `brew install --cask raspberry-pi-imager`

Notes:

- Set _homelab_ public SSH key
- Disable password SSH authentication
- Disable WiFi
- Set Timezone _Europe/Bratislava_
- Set username to _matej_

## Necessary packages

Update and install essential packages:

TL;DR:

```sh
sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get install --yes ca-certificates curl git rsync wget

# git - homelab gitflow
# ca-certificates - required for docker
# rsync - required for log2ram
# curl, wget - general
```

## Install Log2Ram

Install _Log2Ram_

- GitHub: <https://github.com/azlux/log2ram>
- Guide: <https://pimylifeup.com/raspberry-pi-log2ram>

TL;DR:

```sh
cd "$HOME"
git clone https://github.com/azlux/log2ram.git
cd log2ram
sudo bash install.sh
sudo reboot
# later
systemctl status log2ram # verifies installation
```

## Next steps

Continue with guide: "Install docker"
