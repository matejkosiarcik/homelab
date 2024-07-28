#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

cd "$(git rev-parse --show-toplevel)"

print_help() {
    printf 'bash install-app.sh [-n] [-h]\n'
    printf '\n'
    printf 'Arguments:\n'
    printf ' -n  - Dry run\n'
    printf ' -h  - Print usage\n'
}

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

source_dir="${SOURCE_DIR-}"
if [ "$source_dir" = '' ]; then
    printf 'SOURCE_DIR unset\n' >&2
fi

docker_extra_args=''
if [ "$dry_run" -eq 1 ]; then
    docker_extra_args='--dry-run'
fi

# Default deployment location is "~/homelab"
# Can be overriden by setting "DEST_DIR=..."
dest_dir="${DEST_DIR-$HOME/homelab}"
mkdir -p "$dest_dir"

service_name="$(basename "$source_dir")"
target_dir="$dest_dir/machines/current/apps/$service_name"
backup_dir="$dest_dir/.backup/$START_DATE/$service_name"
log_dir="$dest_dir/.log/$START_DATE/$service_name"
log_file="$log_dir/install.txt"
mkdir -p "$log_dir" "$backup_dir"

# Init service data
printf 'Installing %s\n' "$service_name" | tee "$log_file" >&2
if [ ! -d "$source_dir/private" ]; then
    printf 'Init data\n' | tee "$log_file" >&2
    sh "$source_dir/init.sh" 2>&1 | tee "$log_file" >&2
fi

# Backup before updating
if [ -d "$target_dir" ]; then
    if [ -f "$target_dir/docker-compose.yml" ]; then
        printf 'Stop previous deployment\n' | tee "$log_file" >&2
        (cd "$target_dir" && docker compose down $docker_extra_args 2>&1 | tee "$log_file" >&2)
        printf '\n' | tee "$log_file" >&2
    fi

    printf 'Backup previous data\n' | tee "$log_file" >&2
    # TODO: Remove sudo!!!
    sudo cp -R "$target_dir/." "$backup_dir"
else
    mkdir -p "$target_dir"
fi

# Remove old files
sudo rm -rf "$target_dir/log" "$target_dir/private"
find "$target_dir" -mindepth 1 -maxdepth 1 \
    -not \( -name 'data' -and -type d \) -and \
    -exec rm -rf {} \;

# Copy new files
cp "$source_dir/docker-compose.yml" "$target_dir/docker-compose.yml"
if [ -f "$source_dir/docker-compose.prod.yml" ]; then
    cp "$source_dir/docker-compose.prod.yml" "$target_dir/docker-compose.override.yml"
fi
if [ -d "$source_dir/config" ]; then
    cp -R "$source_dir/config/." "$target_dir/config"
fi
if [ -d "$source_dir/private" ]; then
    cp -R "$source_dir/private/." "$target_dir/private"
fi

# Pull docker images
printf 'Pull docker images\n' | tee "$log_file" >&2
(cd "$target_dir" && docker compose pull --ignore-buildable --include-deps --policy always --quiet 2>&1 | tee "$log_file" >&2)
printf '\n' | tee "$log_file" >&2

# Build docker images
printf 'Build docker images\n' | tee "$log_file" >&2
(cd "$source_dir" && docker compose build --pull --with-dependencies --quiet 2>&1 | tee "$log_file" >&2)
printf '\n' | tee "$log_file" >&2

# Run new services
printf 'Start docker containers\n' | tee "$log_file" >&2
# shellcheck disable=SC2248
(cd "$target_dir" && docker compose up --force-recreate --always-recreate-deps --remove-orphans --no-build --detach --wait $docker_extra_args 2>&1 | tee "$log_file" >&2)
printf '\n' | tee "$log_file" >&2
