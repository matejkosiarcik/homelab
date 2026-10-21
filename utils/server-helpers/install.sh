#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

git_dir="$(git rev-parse --show-toplevel)"
server_dir="${git_dir}/servers/.current"

### General config ###

mkdir -p "${HOME}/config" "${HOME}/.log"
sudo mkdir -p '/homelab' '/homelab/config' '/homelab/log'
sudo chown -R "$(whoami)" '/homelab'
sudo chmod a+rwx '/homelab' '/homelab/config' '/homelab/log' # TODO: Remove permissions after homelab user is created

if [ -f "${server_dir}/config/startup.sh" ]; then
    printf '%s [INFO]: Copy startup script\n' "$(date "${datetime_format}")" >&2
    cp "${server_dir}/config/startup.sh" "${HOME}/config/startup.sh"
fi

if [ -f "${server_dir}/config/update.sh" ]; then
    printf '%s [INFO]: Copy update script\n' "$(date "${datetime_format}")" >&2
    cp "${server_dir}/config/update.sh" "${HOME}/config/update.sh"
fi

if [ -f "${server_dir}/config/crontab.cron" ]; then
    printf '%s [INFO]: Installing crontab\n' "$(date "${datetime_format}")" >&2
    crontab - <"${server_dir}/config/crontab.cron"
fi
