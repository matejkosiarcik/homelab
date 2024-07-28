#!/usr/bin/env bash
# shellcheck disable=SC2068
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

currdir="$(cd "$(dirname "$0")" >/dev/null && pwd)"

### Install latest crontab ###

declare current_machine_dir
if [ ! -e "$current_machine_dir/crontab.cron" ]; then
    printf 'Crontab file not found\n' >&2
    exit 1
fi
crontab - <"$current_machine_dir/crontab.cron"

### Preinstall services ###

bash "$currdir/preinstall.sh" $@

### Install all individual services ###

find "$current_machine_dir/apps" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -print0 |
    xargs -0 -I% bash -c "SOURCE_DIR=% bash \"$currdir/install-app.sh\" $@"
