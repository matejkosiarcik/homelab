#!/bin/sh
set -euf

git_dir="$(git rev-parse --show-toplevel)"
server_dir="$git_dir/servers/.current"

### General config ###

mkdir -p "$HOME/config" "$HOME/.log"
sudo mkdir -p /homelab/config /homelab/log
sudo chmod a+rwx /homelab /homelab/config /homelab/log # TODO: Remove permissions after homelab user is created

if [ "$( (find "$server_dir/other-apps/unbound" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' || true) | wc -l)" -ge '1' ]; then
    sudo mkdir -p /homelab/config/unbound /homelab/log/unbound
    sudo chmod a+rwx /homelab/config/unbound /homelab/log/unbound # TODO: Remove permissions after homelab user is created
fi

if [ -f "$server_dir/config/startup.sh" ]; then
    printf 'Copy startup script\n' >&2
    cp "$server_dir/config/startup.sh" "$HOME/config/startup.sh"
fi

if [ -f "$server_dir/config/crontab.cron" ]; then
    printf 'Installing crontab\n' >&2
    crontab - <"$server_dir/config/crontab.cron"
fi

### Unbound config ###

sudo killall unbound || true

if [ "$(sudo find "/homelab/config/unbound" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | wc -l)" -ge '1' ]; then
    printf 'Remove old unbound configs\n' >&2
    sudo find '/homelab/config' -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | while read -r file; do
        sudo rm -f "$file"
    done
fi
if [ "$( (find "$server_dir/other-apps/unbound" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' || true) | wc -l)" -ge '1' ]; then
    printf 'Copy new unbound configs\n' >&2
    find "$server_dir/other-apps/unbound" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | while read -r file; do
        sudo cp "$file" "/homelab/config/unbound/$(basename "$file")"
        sudo chown root:root "/homelab/config/unbound/$(basename "$file")"
        sudo chmod a+rw "/homelab/config/unbound/$(basename "$file")"
    done
    if [ -f '/etc/apparmor.d/local/usr.sbin.unbound' ]; then
        sudo find '/homelab/config/unbound' -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | sed -E 's~$~ rw,~' | sudo sponge '/etc/apparmor.d/local/usr.sbin.unbound'
        sudo find '/homelab/config/unbound' -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' -exec sh -c 'printf "%s/%s\n" "$(dirname "$0")" "$(basename "$0" .conf).sock"' {} \; | sed -E 's~$~ rw,~' | sudo sponge '/etc/apparmor.d/local/usr.sbin.unbound'
        sudo systemctl restart apparmor
    fi
fi
