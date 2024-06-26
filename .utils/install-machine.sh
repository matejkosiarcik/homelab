#!/usr/bin/env bash
# shellcheck disable=SC2068
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

### Install latest crontab ###

declare current_machine_dir
if [ ! -e "$current_machine_dir/crontab.cron" ]; then
    printf 'Crontab file not found\n' >&2
    exit 1
fi
crontab - <"$current_machine_dir/crontab.cron"

### Preinstall services ###

bash "$(git rev-parse --show-toplevel)/.utils/preinstall-all.sh" $@

### Install all individual services ###

find "$current_machine_dir/" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -print0 |
    xargs -0 -I% bash -c "SOURCE_DIR=% bash \"$(git rev-parse --show-toplevel)/.utils/install-service.sh\" $*"
