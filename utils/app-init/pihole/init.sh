#!/bin/sh
set -euf

dev_mode='0'
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d)
        dev_mode='1'
        shift
        ;;
    *)
        printf 'Unknown argument %s\n' "$1"
        exit 1
        ;;
    esac
done

gitroot="$(git rev-parse --show-toplevel)"

output='private'
if [ -e "$output" ]; then
    printf 'Output directory "%s" already exists.\n' "$output" >&2
    exit 1
fi
mkdir "$output"

tmpdir="$(mktemp -d)"

create_password() {
    output_file="$1"
    extra_flags=''
    if [ "$#" -ge 2 ]; then
        extra_flags="$2"
    fi

    if [ "$dev_mode" = '1' ]; then
        printf 'Password123.' >"$output_file" # A simple password for debugging
    else
        # shellcheck disable=SC2068
        python3 "$gitroot/utils/app-init/.shared/password.py" --output "$output_file" $extra_flags
    fi
}

# App
create_password "$output/webpassword.txt"

# Backup
printf 'PASSWORD=%s\n' "$(cat "$output/webpassword.txt")" >>"$output/webui-backup.env"

# Apache proxy
create_password "$tmpdir/apache-status-password.txt" --only-alphanumeric
printf 'status:%s\n' "$(cat "$tmpdir/apache-status-password.txt")" >>"$output/apache-users.txt"
chronic htpasswd -c -B -i "$output/status.htpasswd" status <"$tmpdir/apache-status-password.txt"

rm -rf "$tmpdir"
