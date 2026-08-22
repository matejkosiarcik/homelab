#!/bin/sh
set -euf

kiwix_pid_file='/homelab/tmpfs/pid.txt'
touch "$kiwix_pid_file"
last_shasum_file='/homelab/tmpfs/shasum.txt'
touch "$last_shasum_file"
last_shasum="$(cat "$last_shasum_file")"

is_initial_run='0'
if [ "$(cat "$kiwix_pid_file")" = '' ]; then
    is_initial_run='1'
fi

printf 'Checking valid ZIM files\n' >&2

zim_files_list_new_all_file="$(mktemp)"
zim_files_list_new_valid_file="$(mktemp)"
zim_files_list_new_shasum_file="$(mktemp)"

# Get list of files and filter only valid ones
find '/data' -mindepth 1 -maxdepth 1 -type f -name '*.zim' | sort >"$zim_files_list_new_all_file"
cat "$zim_files_list_new_all_file" | while read -r file; do
    # NOTE: This is the source of the script being slow, the zimcheck call
    # It could be optimized with caching the results for each file (if it is valid) and when it doesn't change (same modified date, same filesize), then we wouldn't have to call it and automatically consider the file valid
    if [ "$is_initial_run" -eq '1' ] || zimcheck --checksum "$file" >/dev/null 2>&1; then
        printf '%s\n' "$file" >>"$zim_files_list_new_valid_file"
    fi
done

# Get file properties for comparisons later
cat "$zim_files_list_new_valid_file" | while read -r file; do
    (printf 'File: %s, Modified at: %s, Size: %s\n' "$file" "$(date -r "$file" || true)" "$(stat -c '%s bytes' -- "$file" || true)") >>"$zim_files_list_new_shasum_file"
done
new_shasum="$(sha256sum <"$zim_files_list_new_shasum_file")"

# If the shasum is the same, abort this run
if [ "$new_shasum" = "$last_shasum" ]; then
    printf 'Server already started and no valid changes in ZIM files detected\n' >&2
    return;
fi

# Save shasum for next run
printf '%s\n' "$new_shasum" >"$last_shasum_file"

# Use placeholder if there are no real ZIM files
zim_files_count="$(cat "$zim_files_list_new_valid_file" | wc -l)"
if [ "$zim_files_count" -eq '0' ]; then
    printf 'No ZIM files found, using placeholder\n' >&2
    printf '/homelab/default-data/empty.zim\n' >>"$zim_files_list_new_valid_file"
fi

if [ "$is_initial_run" -eq '1' ]; then
    printf 'Starting server initially\n' >&2
else
    printf 'Restarting server\n' >&2
    kill "$(cat "$kiwix_pid_file")"
fi

# shellcheck disable=SC2086
kiwix-serve --port=8080 $(cat "$zim_files_list_new_valid_file") &
kiwix_pid="$!"
printf '%s\n' "$kiwix_pid" >"$kiwix_pid_file"
