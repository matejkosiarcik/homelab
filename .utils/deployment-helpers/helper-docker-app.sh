#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

print_help() {
    printf 'sh <script.sh> <command> [-d|--dev] [-f|--force] [-h|--help] [-n|--dry-run] [-p|--prod]\n'
    printf '\n'
    printf 'Commands:\n'
    printf ' start - Start docker app\n'
    printf ' stop - Stop docker app\n'
    printf ' create-secrets - Create app secrets\n'
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
mode=''
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

if [ "$mode" = '' ]; then
    printf 'Mode is unset. Either "dev" or "prod" must be specified.\n' >&2
    print_help
    exit 1
elif [ "$mode" != 'dev' ] && [ "$mode" != 'prod' ]; then
    printf 'Unknown mode "%s"\n' "$mode" >&2
    print_help
    exit 1
fi

# Only set START_DATE if it's not already set from parent script
declare START_DATE
START_DATE="${START_DATE-}"
if [ "$START_DATE" = '' ]; then
    START_DATE="$(date +"%Y-%m-%d_%H-%M-%S")"
fi
export START_DATE

app_dir="$PWD"
git_dir="$(git rev-parse --show-toplevel)"
full_service_name="$(basename "$app_dir")"
log_dir="$HOME/homelab-log/$START_DATE/$full_service_name"
log_file="$log_dir/install.txt"
backup_dir="$HOME/homelab-backup/$START_DATE/$full_service_name"

if [ "$mode" = 'dev' ]; then
    log_file='/dev/null'
elif [ "$mode" = 'prod' ]; then
    mkdir -p "$log_dir" "$backup_dir"
fi

docker_file_args=''
if [ "$mode" = 'prod' ]; then
    docker_file_args='--file docker-compose.yml --file docker-compose.prod.yml'
fi

docker_dryrun_args=''
if [ "$dry_run" = '1' ]; then
    docker_dryrun_args='--dry-run'
fi

docker_stop() {
    printf 'Stop docker containers in %s\n' "$full_service_name" | tee "$log_file" >&2
    # shellcheck disable=SC2086,SC2248
    docker compose $docker_file_args down 2>&1 | tee "$log_file" >&2
}

docker_start() {
    if [ ! -e 'private' ]; then
        printf 'Secrets directory not found in %s. App cannot be run.\n' "$full_service_name"
        exit 1
    fi

    if [ "$mode" = prod ]; then
        if [ -d "$app_dir/log" ]; then
            # TODO: Run without sudo?
            sudo cp -R "$app_dir/log/." "$backup_dir/log"
        fi
        if [ -d "$app_dir/data" ]; then
            # TODO: Run without sudo?
            sudo cp -R "$app_dir/data/." "$backup_dir/data"
        fi
    fi

    # Pull docker images
    printf 'Pull docker images in %s\n' "$full_service_name" | tee "$log_file" >&2
    # shellcheck disable=SC2086
    docker compose $docker_file_args pull --ignore-buildable --include-deps --policy always --quiet 2>&1 | tee "$log_file" >&2
    printf '\n' | tee "$log_file" >&2

    docker_build_args=''
    if [ "$mode" = 'prod' ]; then
        docker_build_args='--quiet'
    fi

    # Build docker images
    printf 'Build docker images in %s\n' "$full_service_name" | tee "$log_file" >&2
    # shellcheck disable=SC2086,SC2248
    docker compose $docker_file_args build --pull --with-dependencies $docker_build_args 2>&1 | tee "$log_file" >&2
    printf '\n' | tee "$log_file" >&2

    docker_deamon_args=''
    if [ "$mode" = 'prod' ]; then
        docker_deamon_args='--detach --wait'
    fi

    # Run new services
    printf 'Start docker containers in %s\n' "$full_service_name" | tee "$log_file" >&2
    if [ "$mode" = 'prod' ]; then
        # shellcheck disable=SC2086,SC2248
        docker compose $docker_file_args up --force-recreate --always-recreate-deps --remove-orphans --no-build $docker_deamon_args $docker_dryrun_args 2>&1 | tee "$log_file" >&2
    elif [ "$mode" = 'dev' ]; then
        # shellcheck disable=SC2086,SC2248
        docker compose --ansi always $docker_file_args up --force-recreate --always-recreate-deps --remove-orphans --no-build $docker_deamon_args $docker_dryrun_args
    fi
    printf '\n' | tee "$log_file" >&2
}

case "$command" in
start)
    docker_stop
    docker_start
    ;;
stop)
    docker_stop
    ;;
create-secrets)
    create_secrets_args=''
    if [ "$force" -eq '1' ]; then
        create_secrets_args="$create_secrets_args --force"
    fi
    if [ "$mode" = 'dev' ]; then
        create_secrets_args="$create_secrets_args --dev"
    fi
    # shellcheck disable=SC2086
    sh "$git_dir/.utils/deployment-helpers/.create-secrets-helpers/main.sh" $create_secrets_args
    ;;
*)
    printf 'Unrecognized command "%s"\n' "$command" >&2
    print_help
    exit 1
    ;;
esac
