#!/bin/sh
set -euf

kiwix_pid="-1"
kiwix_files_list='/homelab/tmpfs/list.txt'

start_server() {
    printf 'Starting server\n'
    printf '' >"$kiwix_files_list"

    find '/data' -mindepth 1 -maxdepth 1 -type f -name '*.zim' -print0 >>"$kiwix_files_list"
    zim_files_count="$(cat "$kiwix_files_list" | sed -E 's~[^\0]~~g' | wc -c)"

    # Use placeholder if there are no real ZIM files
    if [ "$zim_files_count" -eq '0' ]; then
        printf 'No "*.zim" files found, using empty placeholder.\n' >&2
        printf '/homelab/default-data/empty.zim\0' >>"$kiwix_files_list"
    fi

    xargs -0 kiwix-serve --port=8080 <"$kiwix_files_list" &
    kiwix_pid="$!"

    # Wait for apache process to exit
    wait "$kiwix_pid"
}

restart_server() {
    printf 'Restarting server\n'

    kill "$kiwix_pid"
    start_server
}

check_changes() {
    printf 'Checking changes in zim files\n'
    # TODO:
    # - Get list of zim files in /data
    # - Check validity using zimcheck -> only keep valid files
    # - Get sha256sum of each file
    # - If the files are different since last time -> restart server, otherwise do nothing
}

# Watch certificates in background
# inotifywait --monitor --event modify --format '%w%f' --include '.*\.zim' '/data' | xargs -n1 sh -c 'sleep 1 && printf "Zim files changed, checking contents\n" && check_changes' - &

start_server
