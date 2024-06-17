# Install Homelab

Clone homelab repository:

```sh
mkdir git
cd git
cd .
git clone https://github.com/matejkosiarcik/homelab.git
cd ..
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
@reboot sh "$HOME/git/homelab/.current-machine/startup.sh"

# Then
sudo reboot

# Verify installed cron
free -m
ip link show
ip route show
```
