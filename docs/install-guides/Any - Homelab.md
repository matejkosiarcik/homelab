# Install Homelab

Clone homelab repository:

```sh
mkdir -p "$HOME/git"
git clone https://github.com/matejkosiarcik/homelab.git "$HOME/git/homelab"
cd "$HOME"
```

Create startup script:

```sh
cd "$HOME/git/homelab/machines"
ln -s <machine-name> .current
```

Setup default crontab:

```sh
crontab -e

# Add following entry:
@reboot sh "$HOME/git/homelab/machines/.current/startup.sh"

# Then
sudo reboot

# Verify installed cron
free -m
ip link show
ip route show
```
