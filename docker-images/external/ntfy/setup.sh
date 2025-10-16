#!/bin/sh
set -euf

# Wait for user table before creating users
timeout 10s sh <<EOF
while [ ! -e '/var/lib/ntfy/user.db' ]; do
    sleep 1
done
EOF

# Remove unwanted users
ntfy user list 2>&1 | grep -E '^user' | sed -E 's~^user ([a-zA-Z0-9*_-]+) .*$~\1~' | grep -v '\*' | grep -E -v '^(admin|user|publisher)$' | while read -r user; do
    ntfy user remove "$user"
done
ntfy access --reset

# Add predefined users if they don't already exists
if [ "$(ntfy user list 2>&1 | grep -E '^user' | sed -E 's~^user ([a-zA-Z0-9*_-]+) .*$~\1~' | grep -E -c '^admin$' || true)" -eq '0' ]; then
    NTFY_PASSWORD="$NTFY_PASSWORD_ADMIN" ntfy user add admin
fi
if [ "$(ntfy user list 2>&1 | grep -E '^user' | sed -E 's~^user ([a-zA-Z0-9*_-]+) .*$~\1~' | grep -E -c '^user$' || true)" -eq '0' ]; then
    NTFY_PASSWORD="$NTFY_PASSWORD_USER" ntfy user add user
fi
if [ "$(ntfy user list 2>&1 | grep -E '^user' | sed -E 's~^user ([a-zA-Z0-9*_-]+) .*$~\1~' | grep -E -c '^publisher$' || true)" -eq '0' ]; then
    NTFY_PASSWORD="$NTFY_PASSWORD_PUBLISHER" ntfy user add publisher
fi

# Tweak existing users
NTFY_PASSWORD="$NTFY_PASSWORD_MATEJ" ntfy user change-pass matej
ntfy user change-role matej admin
NTFY_PASSWORD="$NTFY_PASSWORD_HOMELAB_VIEWER" ntfy user change-pass homelab-viewer
ntfy user change-role homelab-viewer user
ntfy access homelab-viewer '*' read-only
NTFY_PASSWORD="$NTFY_PASSWORD_HOMELAB_PUBLISHER" ntfy user change-pass homelab-publisher
ntfy user change-role homelab-publisher user
ntfy access homelab-publisher '*' write-only

# Create publishing token if not already created
publisher_tokens_count="$(ntfy token list publisher 2>&1 | grep -c -E '^- tk_' || true)"
if [ "$publisher_tokens_count" -eq '0' ]; then
    printf 'Creating initial publisher token\n' >&2
    ntfy token add publisher
fi
