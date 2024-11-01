#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

print_help() {
    printf 'sh <script.sh> <command> [-d|--dev|-p|--prod] [-h|--help] [-f|--force] [-n|--dry-run]\n'
    printf '\n'
    printf 'Commands:\n'
    printf ' build - Build docker images for all docker apps\n'
    printf ' create-secrets - Create secrets for all docker apps\n'
    printf ' deploy - Deploy all docker apps [DEFAULT]\n'
    printf ' install - Install main server scripts (does not start docker-apps)\n'
    printf ' start - Start all docker apps\n'
    printf ' stop - Stop all docker apps\n'
    printf '\n'
    printf 'Arguments:\n'
    printf ' -d, --dev     - Dev mode\n'
    printf ' -f, --force   - Force\n'
    printf ' -h, --help    - Print help message\n'
    printf ' -n, --dry-run - Dry run\n'
    printf ' -p, --prod    - Production mode\n'
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
mode='prod'
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d | --dev)
        mode='dev'
        shift
        ;;
    -f | --force)
        force='1'
        shift
        ;;
    -n | --dry-run)
        dry_run='1'
        shift
        ;;
    -p | --prod)
        mode='prod'
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

machine_dir="$PWD"
log_dir="$HOME/.homelab-logs/$START_DATE"
log_file="$log_dir/deploy.txt"
server_name="$(basename "$PWD")"

if [ "$mode" = 'dev' ]; then
    log_file='/dev/null'
elif [ "$mode" = 'prod' ]; then
    mkdir -p "$log_dir"
fi

script_args="--$mode"
if [ "$force" = '1' ]; then
    script_args="$script_args --force"
fi
if [ "$dry_run" = '1' ]; then
    script_args="$script_args --dry-run"
fi

machine_stop() {
    if [ -d "$machine_dir/docker-apps" ]; then
        printf 'Stop all docker apps in %s\n' "$server_name" | tee "$log_file" >&2

        sed -E 's~#.*$~~' <"$machine_dir/docker-apps/priority.txt" | (grep -E '.+' || true) | while read -r dir; do
            # shellcheck disable=SC2086
            sh "$machine_dir/docker-apps/$dir/main.sh" stop $script_args
        done

        printf '\n'
    fi
}

machine_build() {
    if [ -d "$machine_dir/docker-apps" ]; then
        printf 'Build docker images for all docker apps in %s\n' "$server_name" | tee "$log_file" >&2

        sed -E 's~#.*$~~' <"$machine_dir/docker-apps/priority.txt" | (grep -E '.+' || true) | while read -r dir; do
            # shellcheck disable=SC2086
            sh "$machine_dir/docker-apps/$dir/main.sh" build $script_args
        done

        printf '\n'
    fi
}

machine_start() {
    if [ -d "$machine_dir/docker-apps" ]; then
        printf 'Start all docker apps in %s\n' "$server_name" | tee "$log_file" >&2

        sed -E 's~#.*$~~' <"$machine_dir/docker-apps/priority.txt" | (grep -E '.+' || true) | while read -r dir; do
            # shellcheck disable=SC2086
            sh "$machine_dir/docker-apps/$dir/main.sh" start $script_args
        done

        printf '\n'
    fi
}

machine_deploy() {
    if [ -d "$machine_dir/docker-apps" ]; then
        printf 'Deploy all docker apps in %s\n' "$server_name" | tee "$log_file" >&2

        sed -E 's~#.*$~~' <"$machine_dir/docker-apps/priority.txt" | (grep -E '.+' || true) | while read -r dir; do
            # shellcheck disable=SC2086
            sh "$machine_dir/docker-apps/$dir/main.sh" deploy $script_args
        done

        printf '\n'
    fi
}

machine_create_secrets() {
    if [ -d "$machine_dir/docker-apps" ]; then
        printf 'Init all docker apps secrets in %s\n' "$server_name" | tee "$log_file" >&2

        sed -E 's~#.*$~~' <"$machine_dir/docker-apps/priority.txt" | (grep -E '.+' || true) | while read -r dir; do
            # shellcheck disable=SC2086
            sh "$machine_dir/docker-apps/$dir/main.sh" create-secrets $script_args
        done

        printf '\n'
    fi
}

machine_install() {
    printf 'Installing crontab\n' >&2
    if [ ! -e "$machine_dir/startup.sh" ]; then
        printf 'Server startup script not found\n' >&2
        exit 1
    fi
    if [ "$dry_run" = '0' ]; then
        cp "$machine_dir/startup.sh" "$HOME/startup.sh"
    fi
    if [ ! -e "$machine_dir/crontab.cron" ]; then
        printf 'Server crontab not found\n' >&2
        exit 1
    fi
    if [ "$dry_run" = '0' ]; then
        crontab - <"$machine_dir/crontab.cron"
    fi
}

case "$command" in
build)
    machine_build
    ;;
create-secrets)
    machine_create_secrets
    ;;
deploy)
    date_start="$(date '+%Y-%m-%d_%H-%M-%S')"
    machine_install
    machine_deploy
    printf '\nAll apps deployed successfully - from %s to %s\n' "$date_start" "$(date '+%Y-%m-%d_%H-%M-%S')"
    ;;
install)
    machine_install
    ;;
start)
    machine_start
    ;;
stop)
    machine_stop
    ;;
*)
    printf 'Unrecognized command "%s"\n' "$command" >&2
    print_help
    exit 1
    ;;
esac
