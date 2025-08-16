#!/bin/sh
set -euf

git_dir="$(git rev-parse --show-toplevel)"
server_dir="$git_dir/servers/.current"

### General config ###

mkdir -p "$HOME/config" "$HOME/.log"
sudo mkdir -p /homelab /homelab/config /homelab/log
sudo chown -R "$(whoami)" /homelab
sudo chmod a+rwx /homelab /homelab/config /homelab/log # TODO: Remove permissions after homelab user is created

if [ -f "$server_dir/config/startup.sh" ]; then
    printf 'Copy startup script\n' >&2
    cp "$server_dir/config/startup.sh" "$HOME/config/startup.sh"
fi

if [ -f "$server_dir/config/update.sh" ]; then
    printf 'Copy update script\n' >&2
    cp "$server_dir/config/update.sh" "$HOME/config/update.sh"
fi

if [ -f "$server_dir/config/crontab.cron" ]; then
    printf 'Installing crontab\n' >&2
    crontab - <"$server_dir/config/crontab.cron"
fi
