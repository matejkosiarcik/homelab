#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
[0-9][0-9][0-9]) milliseconds_format="%3N" ;;
*) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

kiwix_pid_file='/homelab/tmpfs/pid.txt'
touch "${kiwix_pid_file}"
last_shasum_file='/homelab/tmpfs/shasum.txt'
touch "${last_shasum_file}"
last_shasum="$(cat "${last_shasum_file}")"

is_initial_run='0'
if [ "$(cat "${kiwix_pid_file}")" = '' ]; then
    is_initial_run='1'
fi

log INFO 'Checking valid ZIM files'

zim_files_list_new_all_file="$(mktemp)"
zim_files_list_new_valid_file="$(mktemp)"
zim_files_list_new_shasum_file="$(mktemp)"

# Get list of files and filter only valid ones
find '/data' -mindepth 1 -maxdepth 1 -type f -name '*.zim' | sort >"${zim_files_list_new_all_file}"
while read -r file; do
    # NOTE: This is the source of the script being slow, the zimcheck call
    # It could be optimized with caching the results for each file (if it is valid) and when it doesn't change (same modified date, same filesize), then we wouldn't have to call it and automatically consider the file valid
    if [ "${is_initial_run}" -eq '1' ] || zimcheck --checksum "${file}" >'/dev/null' 2>&1; then
        printf '%s\n' "${file}" >>"${zim_files_list_new_valid_file}"
    fi
done <"${zim_files_list_new_all_file}"

# Get file properties for comparisons later
while read -r file; do
    (printf 'File: %s, Modified at: %s, Size: %s\n' "${file}" "$(date -r "${file}" || true)" "$(stat -c '%s bytes' -- "${file}" || true)") >>"${zim_files_list_new_shasum_file}"
done <"${zim_files_list_new_valid_file}"
new_shasum="$(sha256sum <"${zim_files_list_new_shasum_file}")"

# If the shasum is the same, abort this run
if [ "${new_shasum}" = "${last_shasum}" ]; then
    log INFO 'Server already started and no valid changes in ZIM files detected'
    return
fi

# Save shasum for next run
printf '%s\n' "${new_shasum}" >"${last_shasum_file}"

# Use placeholder if there are no real ZIM files
zim_files_count="$(wc -l <"${zim_files_list_new_valid_file}")"
if [ "${zim_files_count}" -eq '0' ]; then
    log WARNING 'No ZIM files found, using placeholder'
    printf '/homelab/default-data/empty.zim\n' >>"${zim_files_list_new_valid_file}"
fi

if [ "${is_initial_run}" -eq '1' ]; then
    log INFO 'Starting server initially'
else
    log INFO 'Restarting server'
    kill "$(cat "${kiwix_pid_file}")"
fi

# shellcheck disable=SC2046
kiwix-serve --port=8080 $(cat "${zim_files_list_new_valid_file}") &
kiwix_pid="${!}"
printf '%s\n' "${kiwix_pid}" >"${kiwix_pid_file}"
