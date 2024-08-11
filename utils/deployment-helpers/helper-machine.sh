#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

print_help() {
    printf 'sh <script.sh> <command> [-f|--force] [-h|--help] [-n|--dry-run]\n'
    printf '\n'
    printf 'Commands:\n'
    printf ' install - Install machine scripts and start docker apps\n'
    printf ' start - Start all docker apps\n'
    printf ' stop - Stop all docker apps\n'
    printf ' init-secrets - Initialize all docker apps secrets\n'
    printf '\n'
    printf 'Arguments:\n'
    printf ' -f, --force   - Force\n'
    printf ' -h, --help    - Print help message\n'
    printf ' -n, --dry-run - Dry run\n'
}

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments. COMMAND must be specified.\n' >&2
    print_help
    exit 1
fi

command="$1"
shift

if [ "$command" = '-h' ] || [ "$command" = '--help' ]; then
    print_help
    exit 0
fi

dry_run='0'
force='0'
mode=''
while [ "$#" -gt 0 ]; do
    case "$1" in
    -f | --force)
        force='1'
        shift
        ;;
    -n | --dry-run)
        dry_run='1'
        shift
        ;;
    *)
        printf 'Unrecognized argument "%s"\n' "$1" >&2
        print_help
        exit 1
        ;;
    esac
done

START_DATE="$(date +"%Y-%m-%d_%H-%M-%S")"
export START_DATE

# This should be set be caller script
declare machine_dir

log_dir="$HOME/homelab-log/$START_DATE"
log_file="$log_dir/install.txt"
mkdir -p "$log_dir"

extra_script_args=''
if [ "$force" = '1' ]; then
    extra_script_args="$extra_script_args --force"
fi
if [ "$dry_run" = '1' ]; then
    extra_script_args="$extra_script_args --dry-run"
fi

machine_stop() {
    if [ -d "$machine_dir/docker-apps" ]; then
        printf 'Stop all docker apps\n' | tee "$log_file" >&2

        find "$machine_dir/docker-apps" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
            sh "$dir/deployment.sh" stop --prod
        done
    fi
}

machine_start() {
    if [ -d "$machine_dir/docker-apps" ]; then
        printf 'Start all docker apps\n' | tee "$log_file" >&2

        find "$machine_dir/docker-apps" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
            sh "$dir/deployment.sh" start --prod
        done
    fi
}

machine_init_secrets() {
    if [ -d "$machine_dir/docker-apps" ]; then
        printf 'Init all docker apps secrets\n' | tee "$log_file" >&2

        find "$machine_dir/docker-apps" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
            sh "$dir/deployment.sh" init-secrets --prod
        done
    fi
}

machine_install() {
    printf 'Installing crontab\n' >&2
    if [ ! -e "$machine_dir/crontab.cron" ]; then
        printf 'Machine crontab file not found\n' >&2
        exit 1
    fi
    if [ "$dry_run" = '0' ]; then
        crontab - <"$machine_dir/crontab.cron"
    fi
}

case "$command" in
install)
    machine_stop
    machine_install
    machine_start
    ;;
start)
    machine_stop
    machine_start
    ;;
stop)
    machine_stop
    ;;
init-secrets)
    machine_init_secrets
    ;;
*)
    printf 'Unrecognized command "%s"\n' "$command" >&2
    print_help
    exit 1
    ;;
esac
