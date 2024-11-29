#!/bin/sh
set -euf

git_dir="$(git rev-parse --show-toplevel)"
server_dir="$git_dir/servers/.current"

### General config ###

mkdir -p "$HOME/config" "$HOME/.log"
sudo mkdir -p /root/config /root/.log

if [ -f "$server_dir/config/startup-initial.sh" ]; then
    printf 'Copy startup-initial script\n' >&2
    cp "$server_dir/config/startup-initial.sh" "$HOME/config/startup-initial.sh"
fi

if [ -f "$server_dir/config/startup-always.sh" ]; then
    printf 'Copy startup-always script\n' >&2
    cp "$server_dir/config/startup-always.sh" "$HOME/config/startup-always.sh"
fi

if [ -f "$server_dir/config/crontab.cron" ]; then
    printf 'Installing crontab\n' >&2
    crontab - <"$server_dir/config/crontab.cron"
fi

### Unbound config ###

sudo killall unbound

if [ "$(sudo find "/root/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | wc -l)" -ge '1' ]; then
    printf 'Remove old unbound configs\n' >&2
    sudo find '/root/config' -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | while read -r file; do
        sudo rm -f "$file"
    done
fi
if [ "$(find "$server_dir/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | wc -l)" -ge '1' ]; then
    printf 'Copy new unbound configs\n' >&2
    find "$server_dir/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | while read -r file; do
        sudo cp "$file" "/root/config/$(basename "$file")"
        sudo chown root:root "$HOME/config/$(basename "$file")"
    done
    if [ -f '/etc/apparmor.d/local/usr.sbin.unbound' ]; then
        sudo find '/root/config' -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | sed -E 's~$~ rw,~' | sudo sponge '/etc/apparmor.d/local/usr.sbin.unbound'
    fi
    sudo systemctl restart apparmor
fi

### Startup services again ###

if [ -f "$HOME/config/startup-always.sh" ]; then
    sh "$HOME/config/startup-always.sh"
fi
