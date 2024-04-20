# Install Docker

- Instructions 32bit: <https://docs.docker.com/engine/install/raspberry-pi-os>
- Instructions 64bit: <https://docs.docker.com/engine/install/debian>

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

Now make docker launchable for non-root users, Instructions: <https://docs.docker.com/engine/install/linux-postinstall>

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
```

## How to connect to macvlan container from Host?

Unfortunetely you can't connect to container running via macvlan directly from the running Host.
At least not without a special (pricy) network equipment.
You can connect to them from other devices on your network though.

Follow this guide to setup "shim router" which allows the host to connect to these containers as well: <https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks>

Here is the main script:

```sh
sudo ip link add macvlan-shim link eth0 type macvlan mode bridge
sudo ip addr add \[shim-ip\]/32 dev macvlan-shim
sudo ip link set macvlan-shim up
sudo ip route add \[containers-ip-range\]/24 dev macvlan-shim
```

Where `[shim-ip]` is the interface address (from `10.1.6.x` address space) and `[containers-ip-range]` is the entire subnet where macvlan containers have assigned IP address.

Problem is these settings do not persist between PC reboots.
To make it persistant:

```sh
crontab -e

# Add following entry:
@reboot sh "$HOME/git/homelab/machines/<machine-name>/startup.sh"
```
