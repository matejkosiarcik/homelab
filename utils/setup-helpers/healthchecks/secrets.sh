#!/bin/sh
set -euf

cd "$(dirname "$0")"

if [ "${BW_SESSION-}" = '' ]; then
    echo 'You must set BW_SESSION env variable before calling this script.' >&2
    exit 1
fi

bw sync                  # Sync latest changes
bw list items >/dev/null # Verify we can access Vaultwarden

rm -f .secrets.env

load_password() {
    # $1 - app name
    # $2 - container name
    # $3 - account name

    itemname="$(printf '%s--%s--%s' "$1" "$2" "$3" | tr '-' '_')"
    bw list items --search "$itemname" | jq -er ".[] | select(.name == \"$itemname\").login.password"
}

printf 'HEALTHCHECKS_API_KEY=%s\n' "$(load_password healthchecks app api-key-readwrite)" >>'.secrets.env'
chmod 0400 '.secrets.env'
