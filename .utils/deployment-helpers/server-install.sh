#!/bin/sh
set -euf

git_dir="$(git rev-parse --show-toplevel)"
server_dir="$git_dir/servers/.current"

### General config ###

if [ -f "$server_dir/startup.sh" ]; then
    printf 'Copy startup script\n' >&2
    cp "$server_dir/startup.sh" "$HOME/startup.sh"
fi

if [ -f "$server_dir/crontab.cron" ]; then
    printf 'Installing crontab\n' >&2
    crontab - <"$server_dir/crontab.cron"
fi

### Unbound config ###

sudo killall unbound

if "$(find '/root' -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | wc -l)" -ge 1 ]; then
    printf 'Remove old unbound config\n' >&2
    find '/root' -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | while read -r file; do
        sudo rm -f "$file"
    done
fi
if "$(find "$server_dir/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | wc -l)" -ge 1 ]; then
    printf 'Copy new unbound configs\n' >&2
    find "$server_dir/config" -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | while read -r file; do
        sudo cp "$file" "/root/$(basename "$file")"
        sudo chown root:root "/root/$(basename "$file")"
    done
fi

tmpfile="$(mktemp)"
find '/root' -mindepth 1 -maxdepth 1 -type f -name 'unbound-*.conf' | sed -E 's~$~ rw,~' | sudo sponge /etc/apparmor.d/local/usr.sbin.unbound
