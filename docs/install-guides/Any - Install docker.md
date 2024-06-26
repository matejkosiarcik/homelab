# Install Docker

- Instructions general: <https://docs.docker.com/engine/install/debian>
- Instructions for Raspberry Pi \(32bit only\): <https://docs.docker.com/engine/install/raspberry-pi-os>

TL;DR 64bit:

```sh
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

sudo apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
sudo docker run hello-world
```

Now make docker launchable for non-root users, instructions: <https://docs.docker.com/engine/install/linux-postinstall>

TL;DR:

```sh
# sudo groupadd docker # Already exists
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

Configure logging driver <https://docs.docker.com/config/containers/logging/local>

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

# Verify edit
cat /etc/docker/daemon.json
```

## How to connect to macvlan container from Host

Unfortunetely you can't connect to container running via macvlan directly from the running Host.
At least not without a special (pricy) network equipment.
You can connect to them from other devices on your network though.

Follow this guide to setup "shim router" which allows the host to connect to these containers as well: <https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks>

This script is already setup in `startup.sh` script.
