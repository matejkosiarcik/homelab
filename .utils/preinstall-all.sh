#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

cd "$(git rev-parse --show-toplevel)"

print_help() {
    printf 'bash preinstall.sh [-n] [-h]\n'
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

# Default deployment location is "~/homelab"
# Can be overriden by setting "DEST_DIR=..."
dest_dir="${DEST_DIR-$HOME/homelab}"
global_log_dir="$dest_dir/.log/$(date +"%Y-%m-%d_%H-%M-%S")"
global_log_file="$global_log_dir/install.txt"
mkdir -p "$dest_dir" "$global_log_dir"

printf 'Preparing destination directory\n' | tee "$global_log_file" >&2

if [ -d "$dest_dir" ]; then
    find "$dest_dir" -mindepth 1 -maxdepth 1 -type d \( -not -name '.*' \) | while read -r dir; do
        if [ -e "$dir/docker-compose.yml" ]; then
            printf 'Stop %s\n' "$(basename "$dir")" | tee "$global_log_file" >&2
            (cd "$dir" && docker compose down 2>&1 | tee "$global_log_file" >&2)
        fi
    done
elif [ -e "$dest_dir" ]; then
    printf 'Destination directory %s exists.\nDelete before proceeding.\n' "$dest_dir" | tee "$global_log_file" >&2
    exit 1
fi
