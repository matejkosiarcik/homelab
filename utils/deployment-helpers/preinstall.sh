#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

cd "$(git rev-parse --show-toplevel)"

print_help() {
    printf 'bash preinstall.sh [-h]\n'
    printf '\n'
    printf 'Arguments:\n'
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
global_log_dir="$dest_dir/.log/$START_DATE"
global_log_file="$global_log_dir/install.txt"
mkdir -p "$dest_dir" "$global_log_dir"

# Stop running apps
extra_args=''
if [ "$dry_run" -eq 1 ]; then
    extra_args='--dry-run'
fi
printf 'Stop all running apps\n' | tee "$global_log_file" >&2
if [ -e "$dest_dir/machines/current/apps" ]; then
    find "$dest_dir/machines/current/apps" -mindepth 1 -maxdepth 1 -type d \( -not -name '.*' \) | while read -r app_dir; do
        if [ -e "$app_dir/docker-compose.yml" ]; then
            printf 'Stop %s\n' "$(basename "$app_dir")" | tee "$global_log_file" >&2
            # shellcheck disable=SC2248
            (cd "$app_dir" && docker compose down $extra_args 2>&1 | tee "$global_log_file" >&2)
        fi
    done
fi

# Copy shared files
printf 'Copy shared files\n' | tee "$global_log_file" >&2
rm -rf "$dest_dir/components"
mkdir -p "$dest_dir/components"
cp -R 'components/.' "$dest_dir/components"
