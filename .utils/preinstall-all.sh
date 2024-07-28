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

while [ "$#" -gt 0 ]; do
    case "$1" in
    -n)
        # Unused
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
global_log_dir="$dest_dir/.log/$(date +"%Y-%m-%d_%H-%M-%S").txt"
global_log_file="$global_log_dir/install.txt"
mkdir -p "$dest_dir" "$global_log_dir"

# printf 'Preparing destination directory\n' | tee "$global_log_file" >&2
# if [ -d "$dest_dir" ]; then
#     find "$dest_dir" -mindepth 1 -maxdepth 1 -type d \( -not -name '.*' \) | while read -r dir; do
#         if [ -e "$dir/docker-compose.yml" ]; then
#             printf 'Stop %s\n' "$(basename "$dir")" | tee "$global_log_file" >&2
#             (cd "$dir" && docker compose down 2>&1 | tee "$global_log_file" >&2)
#         fi
#     done
# elif [ -e "$dest_dir" ]; then
#     printf 'Destination directory %s exists.\nDelete before proceeding.\n' "$dest_dir" | tee "$global_log_file" >&2
#     exit 1
# fi

printf 'Copy shared files\n' | tee "$global_log_file" >&2
rm -rf "$dest_dir/components"
mkdir -p "$dest_dir/components"
cp -R 'components/.' "$dest_dir/components"
