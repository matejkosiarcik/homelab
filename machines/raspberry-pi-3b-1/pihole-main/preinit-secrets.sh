#!/bin/sh
set -euf

cd "$(dirname "$0")"
gitroot="$(git rev-parse --show-toplevel)"

output='private'
rm -rf "$output"
mkdir "$output"

tmpdir="$(mktemp -d)"

# App
python3 "$gitroot/.utils/preinit/password.py" --output "$output/webpassword.txt"

# Backup
printf 'PASSWORD=%s\n' "$(cat "$output/webpassword.txt")" >>"$output/webui-backup.env"

# Apache proxy
python3 "$gitroot/.utils/preinit/password.py" --output "$tmpdir/apache-status-password.txt" --only-alphanumeric
printf 'status:%s\n' "$(cat "$tmpdir/apache-status-password.txt")" >>"$output/apache-users.txt"
htpasswd -c -B -i "$output/status.htpasswd" status <"$tmpdir/apache-status-password.txt"

rm -rf "$tmpdir"
