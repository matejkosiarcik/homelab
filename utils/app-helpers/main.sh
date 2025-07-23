#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

print_help() {
    printf 'sh <script.sh> <command> [-d|--dev|-p|--prod] [-h|--help] [-f|--force] [-n|--dry-run]\n'
    printf '\n'
    printf 'Commands:\n'
    printf ' build - Build docker images for current app\n'
    printf ' deploy - Deploy current docker app [DEFAULT]\n'
    printf ' start - Start current docker app\n'
    printf ' stop - Stop current docker app\n'
    printf ' secrets - Create app secrets\n'
    printf '\n'
    printf 'Arguments:\n'
    printf ' -d, --dev         - Dev mode\n'
    printf ' -p, --prod        - Production mode\n'
    printf ' -f, --force       - Force\n'
    printf ' -h, --help        - Print help message\n'
    printf ' -n, --dry-run     - Dry run\n'
    printf ' --online          - (default) Access vaultwarden to get latest secrets\n'
    printf ' --offline         - Only generate local secrets, do not access vaultwarden\n'
    printf ' --deploy-always   - (default) Always deploy app\n'
    printf ' --deploy-onchange - Only deploy app if it changed\n'
}

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments. COMMAND must be specified.\n' >&2
    print_help
    exit 1
fi

tmpdir="$(mktemp -d)"

command="$1"
shift

if [ "$command" = '-h' ] || [ "$command" = '--help' ]; then
    print_help
    exit 0
fi

online_mode='online'
deploy_mode='always'
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
    --online)
        online_mode='online'
        shift
        ;;
    --offline)
        online_mode='offline'
        shift
        ;;
    --deploy-onchange)
        deploy_mode='onchange'
        shift
        ;;
    --deploy-always)
        deploy_mode='always'
        shift
        ;;
    *)
        printf 'Unrecognized argument "%s"\n' "$1" >&2
        print_help
        exit 1
        ;;
    esac
done

if [ "$mode" = '' ] && [ "${HOMELAB_ENV-}" != '' ]; then
    mode="$HOMELAB_ENV"
fi
if [ "$mode" != 'dev' ] && [ "$mode" != 'prod' ]; then
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
full_app_name="$(basename "$app_dir" | sed -E 's~^\.~~')"
log_dir="$HOME/.homelab-logs/$START_DATE-$full_app_name"
log_file="$log_dir/deploy.txt"
backup_dir="$HOME/.homelab-backup/$START_DATE-$full_app_name"

if [ "$mode" = 'dev' ]; then
    log_file='/dev/null'
elif [ "$mode" = 'prod' ]; then
    mkdir -p "$log_dir" "$backup_dir"
fi

docker_file_args=''
if [ "$mode" = 'prod' ]; then
    docker_file_args='--file compose.yml --file compose.prod.yml'
fi

docker_dryrun_args=''
if [ "$dry_run" = '1' ]; then
    docker_dryrun_args='--dry-run'
fi

pull_images='0'
if [ "$command" = 'build' ] || [ "$command" = 'pull' ]; then
    pull_images='1'
fi

if [ "$command" != 'secrets' ] && [ ! -e 'app-secrets' ]; then
    printf 'Secrets directory not found in %s. App cannot be run.\n' "$full_app_name"
    exit 1
fi

# Remove values that may stick around from previous runs
unset DOCKER_COMPOSE_APP_NAME
unset DOCKER_COMPOSE_APP_TYPE
unset DOCKER_COMPOSE_ENV
unset DOCKER_COMPOSE_NETWORK_DOMAIN
unset DOCKER_COMPOSE_NETWORK_IP
unset DOCKER_COMPOSE_NETWORK_URL
unset DOCKER_COMPOSE_REPOROOT_PATH

# Get env files
docker_compose_args="$docker_file_args"
if [ "$mode" = 'dev' ]; then
    docker_compose_args="$docker_compose_args --ansi always"
fi
if [ -f "$app_dir/config/compose.env" ]; then
    docker_compose_args="$docker_compose_args --env-file $app_dir/config/compose.env"
    # shellcheck source=/dev/null
    . "$app_dir/config/compose.env"
fi
if [ -f "$app_dir/config/compose-$mode.env" ]; then
    docker_compose_args="$docker_compose_args --env-file $app_dir/config/compose-$mode.env"
    # shellcheck source=/dev/null
    . "$app_dir/config/compose-$mode.env"
fi

# Get default value for docker compose
extra_docker_compose_env="$tmpdir/compose.env"
touch "$extra_docker_compose_env"

if [ "${DOCKER_COMPOSE_ENV-}" = '' ]; then
    DOCKER_COMPOSE_ENV="$mode"
fi
export DOCKER_COMPOSE_ENV
printf 'DOCKER_COMPOSE_ENV=%s\n' "$DOCKER_COMPOSE_ENV" >>"$extra_docker_compose_env"

if [ "${DOCKER_COMPOSE_CURRENT_USER-}" = '' ]; then
    DOCKER_COMPOSE_CURRENT_USER="$(id -u)"
fi
export DOCKER_COMPOSE_CURRENT_USER
printf 'DOCKER_COMPOSE_CURRENT_USER=%s\n' "$DOCKER_COMPOSE_CURRENT_USER" >>"$extra_docker_compose_env"

if [ "${DOCKER_COMPOSE_APP_NAME-}" = '' ]; then
    DOCKER_COMPOSE_APP_NAME="$full_app_name"
fi
export DOCKER_COMPOSE_APP_NAME
printf 'DOCKER_COMPOSE_APP_NAME=%s\n' "$DOCKER_COMPOSE_APP_NAME" >>"$extra_docker_compose_env"

if [ "${DOCKER_COMPOSE_APP_TYPE-}" = '' ]; then
    DOCKER_COMPOSE_APP_TYPE="$(basename "$app_dir")"
fi
export DOCKER_COMPOSE_APP_TYPE
printf 'DOCKER_COMPOSE_APP_TYPE=%s\n' "$DOCKER_COMPOSE_APP_TYPE" >>"$extra_docker_compose_env"

if [ "${DOCKER_COMPOSE_APP_PATH-}" = '' ]; then
    DOCKER_COMPOSE_APP_PATH="$app_dir"
fi
export DOCKER_COMPOSE_APP_PATH
printf 'DOCKER_COMPOSE_APP_PATH=%s\n' "$DOCKER_COMPOSE_APP_PATH" >>"$extra_docker_compose_env"

if [ "${DOCKER_COMPOSE_REPOROOT_PATH-}" = '' ]; then
    DOCKER_COMPOSE_REPOROOT_PATH="$(git rev-parse --show-toplevel)"
fi
export DOCKER_COMPOSE_REPOROOT_PATH
printf 'DOCKER_COMPOSE_REPOROOT_PATH=%s\n' "$DOCKER_COMPOSE_REPOROOT_PATH" >>"$extra_docker_compose_env"

if [ "${DOCKER_COMPOSE_NETWORK_DOMAIN-}" = '' ]; then
    if [ "$mode" = 'prod' ]; then
        DOCKER_COMPOSE_NETWORK_DOMAIN="$DOCKER_COMPOSE_APP_NAME.matejhome.com"
    elif [ "$mode" = 'dev' ]; then
        DOCKER_COMPOSE_NETWORK_DOMAIN="localhost"
    else
        printf 'Unknown mode "%s"\n' "$mode" >&2
        exit 1
    fi
fi
export DOCKER_COMPOSE_NETWORK_DOMAIN
printf 'DOCKER_COMPOSE_NETWORK_DOMAIN=%s\n' "$DOCKER_COMPOSE_NETWORK_DOMAIN" >>"$extra_docker_compose_env"

if [ "${DOCKER_COMPOSE_NETWORK_IP-}" = '' ]; then
    if [ "$mode" = 'dev' ]; then
        DOCKER_COMPOSE_NETWORK_IP="127.0.0.1"
    elif [ "$mode" = 'prod' ]; then
        DOCKER_COMPOSE_NETWORK_IP="256.256.256.256" # Intentionally invalid IP address as placeholder
    else
        printf 'Unknown mode "%s"\n' "$mode" >&2
        exit 1
    fi
fi
export DOCKER_COMPOSE_NETWORK_IP
printf 'DOCKER_COMPOSE_NETWORK_IP=%s\n' "$DOCKER_COMPOSE_NETWORK_IP" >>"$extra_docker_compose_env"

if [ "${DOCKER_COMPOSE_NETWORK_URL-}" = '' ]; then
    if [ "$mode" = 'prod' ]; then
        DOCKER_COMPOSE_NETWORK_URL="https://$DOCKER_COMPOSE_NETWORK_DOMAIN"
    elif [ "$mode" = 'dev' ]; then
        DOCKER_COMPOSE_NETWORK_URL="https://localhost:8443"
    else
        printf 'Unknown mode "%s"\n' "$mode" >&2
        exit 1
    fi

    if [ "$DOCKER_COMPOSE_APP_TYPE" = 'samba' ]; then
        DOCKER_COMPOSE_NETWORK_URL="$(printf '%s' "$DOCKER_COMPOSE_NETWORK_URL" | sed -E 's~^https?://~smb://~;s~:[0-9]+$~~')"
    fi
fi
export DOCKER_COMPOSE_NETWORK_URL
printf 'DOCKER_COMPOSE_NETWORK_URL=%s\n' "$DOCKER_COMPOSE_NETWORK_URL" >>"$extra_docker_compose_env"

# Ensure app_type is valid
app_count="$(find "$DOCKER_COMPOSE_REPOROOT_PATH/docker-compose" -maxdepth 1 -mindepth 1 -type d -name "$DOCKER_COMPOSE_APP_TYPE" | wc -l)"
if [ "$app_count" -ne 1 ]; then
    printf 'App %s not found\n' "$DOCKER_COMPOSE_APP_TYPE" >&2
    exit 1
fi

docker_compose_args="$docker_compose_args --project-name $DOCKER_COMPOSE_APP_NAME --env-file $extra_docker_compose_env"

get_docker_compose_images() {
    docker compose $docker_compose_args config |
        yq -r '.services[].container_name' |
        sort |
        xargs -n1 sh -c 'printf "%s " "$1" && ( docker image inspect "$1" --format json 2>/dev/null || true ) | jq -r "(.[0].RootFS.Layers // [\"N/A\"])[]" | shasum | sed -E "s~ .+~~"' -
        >"$tmpdir/docker-images.txt"
}

get_docker_compose_images
mv "$tmpdir/docker-images.txt" "$tmpdir/docker-images-before.txt"
printf 'Before:\n' >&2
cat "$tmpdir/docker-images-before.txt" >&2

docker_stop() {
    printf 'Stop docker containers in %s\n' "$full_app_name" | tee "$log_file" >&2

    docker_stop_args="$docker_compose_args down $docker_dryrun_args"

    if [ "$mode" = 'prod' ]; then
        # shellcheck disable=SC2086
        time docker compose $docker_stop_args 2>&1 | tee "$log_file" >&2
    elif [ "$mode" = 'dev' ]; then
        # shellcheck disable=SC2086
        docker compose $docker_stop_args
    fi
    printf '\n' | tee "$log_file" >&2
}

docker_pull() {
    docker_pull_args="$docker_compose_args pull --ignore-buildable --include-deps $docker_dryrun_args"
    if [ "$mode" = 'prod' ]; then
        docker_pull_args="$docker_pull_args --policy always --quiet"
    elif [ "$mode" = 'dev' ]; then
        docker_pull_args="$docker_pull_args --policy missing"
    fi

    printf 'Pull docker images in %s\n' "$full_app_name" | tee "$log_file" >&2
    if [ "$mode" = 'prod' ]; then
        # shellcheck disable=SC2086
        time docker compose $docker_pull_args 2>&1 | tee "$log_file" >&2
    elif [ "$mode" = 'dev' ]; then
        # shellcheck disable=SC2086
        docker compose $docker_pull_args
    fi
    printf '\n' | tee "$log_file" >&2
}

docker_build() {
    docker_build_args="$docker_compose_args build --with-dependencies $docker_dryrun_args"
    # if [ "$mode" = 'prod' ]; then
    #     docker_build_args="$docker_build_args --quiet"
    # fi
    if [ "$pull_images" = '1' ]; then
        docker_build_args="$docker_build_args --pull"
    fi

    printf 'Build docker images in %s\n' "$full_app_name" | tee "$log_file" >&2
    if [ "$mode" = 'prod' ]; then
        # shellcheck disable=SC2086
        time docker compose $docker_build_args 2>&1 | tee "$log_file" >&2
    elif [ "$mode" = 'dev' ]; then
        # shellcheck disable=SC2086
        docker compose $docker_build_args
    fi
    printf '\n' | tee "$log_file" >&2
}

docker_start() {
    if [ "$mode" = prod ]; then
        if [ -d "$app_dir/app-logs" ]; then
            # TODO: Run without sudo?
            sudo cp -R "$app_dir/app-logs/." "$backup_dir/app-logs"
            sudo rm -rf "$app_dir/app-logs"
        fi
        # if [ -d "$app_dir/app-data" ]; then
        #     # TODO: Run without sudo?
        #     sudo cp -R "$app_dir/app-data/." "$backup_dir/app-data"
        # fi
    fi

    #
    # Start docker containers
    #

    docker_up_args="$docker_compose_args up --force-recreate --always-recreate-deps --remove-orphans --no-build $docker_dryrun_args"
    if [ "$mode" = 'prod' ]; then
        docker_up_args="$docker_up_args --detach --wait"
    fi

    printf 'Start docker containers in %s\n' "$full_app_name" | tee "$log_file" >&2
    if [ "$mode" = 'prod' ]; then
        # shellcheck disable=SC2086
        time docker compose $docker_up_args 2>&1 | tee "$log_file" >&2
    elif [ "$mode" = 'dev' ]; then
        # shellcheck disable=SC2086
        docker compose $docker_up_args
    fi
    printf '\n' | tee "$log_file" >&2
}

create_secrets() {
    create_secrets_args="--$mode --$online_mode"
    if [ "$force" -eq '1' ]; then
        create_secrets_args="$create_secrets_args --force"
    fi
    # shellcheck disable=SC2086
    sh "$git_dir/.utils/secrets-helpers/main.sh" $create_secrets_args
}

case "$command" in
build)
    # docker_pull
    docker_build
    ;;
deploy)
    docker_build

    get_docker_compose_images
    mv "$tmpdir/docker-images.txt" "$tmpdir/docker-images-after.txt"
    printf 'After:\n' >&2
    cat "$tmpdir/docker-images-after.txt" >&2

    if [ "$deploy_mode" = 'always' ] || ( [ "$deploy_mode" = 'onchange' ] && [ "$(shasum "$tmpdir/docker-images-before.txt")" != "$(shasum "$tmpdir/docker-images-after.txt")" ] ); then
        printf 'Change!!!\n'
        docker_stop
        # docker network prune -f # Might help with services problems sometimes not being able to bind ports
        # sleep 1                 # Should help with container clash problems
        docker_start
    fi
    printf 'Deployment of %s successful\n\n' "$full_app_name"
    ;;
pull)
    docker_pull
    ;;
start)
    docker_start
    ;;
stop)
    docker_stop
    ;;
secrets)
    create_secrets
    ;;
*)
    printf 'Unrecognized command "%s"\n' "$command" >&2
    print_help
    exit 1
    ;;
esac

rm -rf "$tmpdir"
