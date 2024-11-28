#!/bin/sh
set -euf

git_dir="$(git rev-parse --show-toplevel)"
server_dir="$git_dir/servers/.current"

### General config ###

mkdir -p "$HOME/config" "$HOME/.log"

if [ -f "$server_dir/config/startup.sh" ]; then
    printf 'Copy startup script\n' >&2
    cp "$server_dir/config/startup.sh" "$HOME/config/startup.sh"
fi

if [ -f "$server_dir/config/crontab.cron" ]; then
    printf 'Installing crontab\n' >&2
    crontab - <"$server_dir/config/crontab.cron"
fi

### Unbound config ###

sudo killall unbound

if [ "$(find "$HOME/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | wc -l)" -ge '1' ]; then
    printf 'Remove old unbound configs\n' >&2
    sudo find "$HOME/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | while read -r file; do
        sudo rm -f "$file"
    done
fi
if [ "$(find "$server_dir/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | wc -l)" -ge '1' ]; then
    printf 'Copy new unbound configs\n' >&2
    find "$server_dir/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | while read -r file; do
        cp "$file" "$HOME/config/$(basename "$file")"
        sudo chown root:root "$HOME/config/$(basename "$file")"
    done
fi

sudo find "$HOME/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | sed -E 's~$~ rw,~' | sudo sponge /etc/apparmor.d/local/usr.sbin.unbound
sudo systemctl restart apparmor
