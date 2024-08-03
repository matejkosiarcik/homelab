#!/bin/sh
set -euf

cd "$(dirname "$0")"
gitroot="$(git rev-parse --show-toplevel)"

output='private'
rm -rf "$output"
mkdir "$output"

tmpdir="$(mktemp -d)"

# Database
python3 "$gitroot/.utils/preinit/password.py" --output "$output/database-password.txt"
printf 'PGPASSWORD=%s\n' "$(cat "$output/database-password.txt")" >>"$output/database-backup.env"

# App
python3 "$gitroot/.utils/preinit/password.py" --output "$tmpdir/secret.txt" --only-alphanumeric
printf 'SECRET_KEY=%s\n' "$(cat "$tmpdir/secret.txt")" >>"$output/app.env"
printf 'DB_PASSWORD=%s\n' "$(cat "$output/database-password.txt")" >>"$output/app.env"

rm -rf "$tmpdir"
