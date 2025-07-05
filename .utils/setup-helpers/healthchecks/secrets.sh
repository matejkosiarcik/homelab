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

    bw list items --search "homelab--$1--$2--$3" | jq -er ".[] | select(.name == \"homelab--$1--$2--$3\").login.password"
}

printf 'HEALTHCHECKS_API_KEY=%s\n' "$(load_password healthchecks app api-key-readwrite)" >>'.secrets.env'
chmod 0400 '.secrets.env'
