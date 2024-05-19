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
echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
sudo curl https://azlux.fr/repo.gpg -o /usr/share/keyrings/azlux-archive-keyring.gpg
sudo apt-get update
sudo apt-get install --yes log2ram
sudo reboot

# Old installat method:
# git clone https://github.com/azlux/log2ram.git
# cd log2ram
# sudo bash install.sh
# sudo reboot

# Verify installation
systemctl status log2ram

# Modify settings (disable email)
sudo nano /etc/log2ram.conf
```

## Next steps

Continue with guide: "Install docker"
