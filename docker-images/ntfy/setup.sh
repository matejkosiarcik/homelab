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
    printf '%s\n' "${*}" | while IFS= read -r log_message || [ -n "${log_message}" ]; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

# Wait for user table before creating users
timeout 10s sh <<EOF
while [ ! -e '/var/lib/ntfy/user.db' ]; do
    sleep 1
done
EOF

# Add predefined users if they don't already exists
if [ "$(ntfy user list 2>&1 | grep -E '^user' | sed -E 's~^user ([a-zA-Z0-9*_-]+) .*$~\1~' | grep -E -c '^matej$' || true)" -eq '0' ]; then
    NTFY_PASSWORD="${NTFY_PASSWORD_MATEJ}" ntfy user add matej
fi
if [ "$(ntfy user list 2>&1 | grep -E '^user' | sed -E 's~^user ([a-zA-Z0-9*_-]+) .*$~\1~' | grep -E -c '^homelab-publisher$' || true)" -eq '0' ]; then
    NTFY_PASSWORD="${NTFY_PASSWORD_HOMELAB_PUBLISHER}" ntfy user add homelab-publisher
fi
if [ "$(ntfy user list 2>&1 | grep -E '^user' | sed -E 's~^user ([a-zA-Z0-9*_-]+) .*$~\1~' | grep -E -c '^homelab-viewer$' || true)" -eq '0' ]; then
    NTFY_PASSWORD="${NTFY_PASSWORD_HOMELAB_VIEWER}" ntfy user add homelab-viewer
fi
if [ "$(ntfy user list 2>&1 | grep -E '^user' | sed -E 's~^user ([a-zA-Z0-9*_-]+) .*$~\1~' | grep -E -c '^homelab-test$' || true)" -eq '0' ]; then
    NTFY_PASSWORD="${NTFY_PASSWORD_HOMELAB_TEST}" ntfy user add homelab-test
fi

# Remove unwanted users
ntfy user list 2>&1 | grep -E '^user' | sed -E 's~^user ([a-zA-Z0-9*_-]+) .*$~\1~' | grep -v '\*' | grep -E -v '^(matej|homelab-publisher|homelab-viewer|homelab-test)$' | while read -r user; do
    ntfy user remove "${user}"
done

# Reset access for all users
ntfy access --reset

# Change roles of all users to "user"
ntfy user list | grep -E '^user ' | sed -E 's~^user ([a-zA-Z0-9_-]+) .+$~\1~' | grep -v -E '^user ' | while read -r user; do
    ntfy user change-role "${user}" user
done

# Tweak existing users
NTFY_PASSWORD="${NTFY_PASSWORD_MATEJ}" ntfy user change-pass matej
ntfy user change-role matej admin
NTFY_PASSWORD="${NTFY_PASSWORD_HOMELAB_PUBLISHER}" ntfy user change-pass homelab-publisher
ntfy access homelab-publisher '*' write-only
NTFY_PASSWORD="${NTFY_PASSWORD_HOMELAB_VIEWER}" ntfy user change-pass homelab-viewer
ntfy access homelab-viewer '*' read-only
NTFY_PASSWORD="${NTFY_PASSWORD_HOMELAB_TEST}" ntfy user change-pass homelab-test
ntfy access homelab-test '*' read-only

# Create publishing token if not already created
publisher_tokens_count="$(ntfy token list homelab-publisher 2>&1 | grep -c -E '^- tk_' || true)"
if [ "${publisher_tokens_count}" -eq '0' ]; then
    log INFO 'Creating initial homelab-publisher token'
    ntfy token add homelab-publisher
fi
