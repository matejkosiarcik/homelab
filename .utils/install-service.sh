#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

cd "$(git rev-parse --show-toplevel)"

print_help() {
    printf 'bash install-service.sh [-n] [-h]\n'
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

# Default deployment location is "~/homelab"
# Can be overriden by setting "DEST_DIR=..."
dest_dir="${DEST_DIR-$HOME/homelab}"
global_log_dir="$dest_dir/.log/$(date +"%Y-%m-%d_%H-%M-%S").txt"
global_log_file="$global_log_dir/install.txt"

check_service_already_exist="$(if [ -e "$dest_dir" ]; then printf '1'; else printf '0'; fi)"

mkdir -p "$dest_dir" "$global_log_dir"

service_name="$(basename "$source_dir")"
printf 'Installing %s\n' "$service_name" | tee "$global_log_file" >&2

target_dir="$dest_dir/machines/current/$service_name"
backup_dir="$dest_dir/.backup/$service_name/$(date +"%Y-%m-%d_%H-%M-%S")"
log_dir="$dest_dir/.log/$service_name/$(date +"%Y-%m-%d_%H-%M-%S")"
log_file="$log_dir/install.txt"
mkdir -p "$log_dir" "$backup_dir"

# Backup before updating
if [ -d "$target_dir" ]; then
    if [ -f "$target_dir/docker-compose.yml" ]; then
        printf 'Stop:\n' | tee "$log_file" >&2
        (cd "$target_dir" && docker compose down 2>&1 | tee "$log_file" >&2)
        printf '\n' | tee "$log_file" >&2
    fi
    # TODO: Remove sudo!!!
    sudo cp -R "$target_dir/." "$backup_dir"
else
    mkdir -p "$target_dir"
fi

# Remove old files
if [ -e "$target_dir/log" ]; then
    sudo rm -rf "$target_dir/log"
fi
find "$target_dir" -mindepth 1 -maxdepth 1 \
    -not \( -name 'data' -and -type d \) -and \
    -not \( -name 'private' -and -type d \) \
    -exec rm -rf {} \;

# Copy new files
cp "$source_dir/docker-compose.yml" "$target_dir/docker-compose.yml"
if [ -f "$source_dir/docker-compose.prod.yml" ]; then
    cp "$source_dir/docker-compose.prod.yml" "$target_dir/docker-compose.override.yml"
fi
find "$source_dir" -mindepth 1 -maxdepth 1 \
    \( -name 'config' -and -type d \) \
    -exec cp -R "{}/." "$target_dir/config" \;

# Pull docker images
printf 'Pull:\n' | tee "$log_file" >&2
(cd "$target_dir" && docker compose pull --ignore-buildable --include-deps --policy always --quiet 2>&1 | tee "$log_file" >&2)
printf '\n' | tee "$log_file" >&2

# Build docker images
printf 'Build:\n' | tee "$log_file" >&2
(cd "$source_dir" && docker compose build --pull --with-dependencies --quiet 2>&1 | tee "$log_file" >&2)
printf '\n' | tee "$log_file" >&2

if [ "$check_service_already_exist" -eq 0 ]; then
    printf 'THIS IS FIRST DEPLOYMENT OF %s\n' "$service_name"
    printf 'Intentionally failing so you can setup private secrets\n'
    printf 'Then rerun deployment process again\n'
    exit 1
fi

# Run new services
extra_args=''
if [ "$dry_run" -eq 1 ]; then
    extra_args='--dry-run'
fi
printf 'Up:\n' | tee "$log_file" >&2
# shellcheck disable=SC2248
(cd "$target_dir" && docker compose up --force-recreate --always-recreate-deps --remove-orphans --no-build --detach --wait $extra_args 2>&1 | tee "$log_file" >&2)
printf '\n' | tee "$log_file" >&2
