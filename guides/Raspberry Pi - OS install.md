# RPi OS install with all bells and whistles

## Install OS

Install OS via RaspberryPi Imager

- GitHub: <https://github.com/raspberrypi/rpi-imager>
- Blogpost: <https://www.raspberrypi.com/news/raspberry-pi-imager-imaging-utility/>
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
```

## Install Log2Ram

Install _Log2Ram_

- GitHub: <https://github.com/azlux/log2ram>
- Guide: <https://pimylifeup.com/raspberry-pi-log2ram/>

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

## Install Docker

- Instructions 32bit: https://docs.docker.com/engine/install/raspberry-pi-os/
- Instructions 64bit: https://docs.docker.com/engine/install/debian

TL;DR 64bit:

```sh
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

sudo apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
sudo docker run hello-world
```

Now make docker launchable for non-root users, Instructions: https://docs.docker.com/engine/install/linux-postinstall/

TL;DR:

```sh
# sudo groupadd docker
sudo usermod -aG docker matej
sudo reboot

# Verify installation
docker run hello-world
```

Start docker on startup:

```sh
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

Configure logging driver https://docs.docker.com/config/containers/logging/local/

TL;DR:

```sh
sudo nano /etc/docker/daemon.json

# Content:
{
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m"
  }
}
```
