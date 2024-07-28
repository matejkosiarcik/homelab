#!/bin/sh
set -euf

gitroot="$(git rev-parse --show-toplevel)"

output='private'
if [ -e "$output" ]; then
    printf 'Output directory "%s" already exists.' "$output" >&2
    exit 1
fi
mkdir "$output"

tmpdir="$(mktemp -d)"

# App
python3 "$gitroot/.utils/preinit/.shared/password.py" --output "$output/webpassword.txt"

# Backup
printf 'PASSWORD=%s\n' "$(cat "$output/webpassword.txt")" >>"$output/webui-backup.env"

# Apache proxy
python3 "$gitroot/.utils/preinit/.shared/password.py" --output "$tmpdir/apache-status-password.txt" --only-alphanumeric
printf 'status:%s\n' "$(cat "$tmpdir/apache-status-password.txt")" >>"$output/apache-users.txt"
chronic htpasswd -c -B -i "$output/status.htpasswd" status <"$tmpdir/apache-status-password.txt"

rm -rf "$tmpdir"
