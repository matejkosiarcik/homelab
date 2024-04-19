#!/usr/bin/env bash
set -eufo pipefail
cd "$(dirname "$0")"

print_help() {
    printf 'bash install.sh [-n] [-h]\n'
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
dist_prefix="${DEST_DIR-$HOME/homelab}"

component="$(basename "$source_dir")"
printf 'Installing %s\n' "$component"

source_dir="$PWD/$component"
target_dir="$dist_prefix/$component"
backup_dir="$dist_prefix/.backup/$component/$(date +"%Y-%m-%d_%H-%M-%S")"
log_dir="$dist_prefix/.log/$component/$(date +"%Y-%m-%d_%H-%M-%S")"

mkdir -p "$log_dir" "$backup_dir"

# Backup before updating
if [ -d "$target_dir" ]; then
    if [ -f "$target_dir/docker-compose.yml" ]; then
        (cd "$target_dir" && docker compose down 2>&1 | tee "$log_dir/docker-compose-down.txt")
    fi
    cp -r "$target_dir/" "$backup_dir/"
else
    mkdir -p "$target_dir"
fi

# Remove old config files
find "$target_dir" -maxdepth 1 -type f -name 'docker-compose*.yml' -delete
find "$target_dir" -maxdepth 1 -type d -name 'config-public' -exec rm -rf {} \;

# Copy new config files
cp "$source_dir/docker-compose.yml" "$target_dir/docker-compose.yml"
cp "$source_dir/docker-compose.prod.yml" "$target_dir/docker-compose.override.yml"

# Run new services
(cd "$target_dir" && docker compose pull --ignore-buildable --include-deps --policy always 2>&1 | tee "$log_dir/docker-compose-pull.txt")
extra_args=''
if [ "$dry_run" -eq 1 ]; then
    extra_args='--dry-run'
fi
# shellcheck disable=SC2248
(cd "$target_dir" && docker compose up --force-recreate --always-recreate-deps --remove-orphans --build --detach --wait $extra_args 2>&1 | tee "$log_dir/docker-compose-up.txt")
