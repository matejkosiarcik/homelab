#!/usr/bin/env bash
# shellcheck disable=SC2068
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

currdir="$(cd "$(dirname "$0")" >/dev/null && pwd)"

START_DATE="$(date +"%Y-%m-%d_%H-%M-%S")"
export START_DATE

dry_run='0'
while [ "$#" -gt 0 ]; do
    case "$1" in
    -n)
        dry_run="1"
        shift
        ;;
    -h)
        print_help
        exit 0
        ;;
    *)
        print_help
        exit 1
        ;;
    esac
done

### Install latest crontab ###

printf 'Installing crontab\n' >&2
declare current_machine_dir
if [ ! -e "$current_machine_dir/crontab.cron" ]; then
    printf 'Machine crontab file not found\n' >&2
    exit 1
fi
if [ "$dry_run" = '0' ]; then
    crontab - <"$current_machine_dir/crontab.cron"
fi

### Execute startup script ###

# printf 'Running startup script\n' >&2
# if [ "$dry_run" = '0' ] && [ -e "$current_machine_dir/startup.sh" ]; then
#     bash "$current_machine_dir/startup.sh"
# fi

### Preinstall services ###

bash "$currdir/preinstall.sh" $@

### Install all individual services ###

find "$current_machine_dir/docker-apps" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -print0 |
    xargs -0 -I% bash -c "SOURCE_DIR=% bash \"$currdir/install-docker-app.sh\" $@"
