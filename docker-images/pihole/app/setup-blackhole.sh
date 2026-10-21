#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

sql() {
    command="${1}"
    i=0
    while [ "${i}" -le '3' ]; do
        i="$((i + 1))"
        status='0'
        pihole-FTL sqlite3 '/etc/pihole/gravity.db' "${command}" || {
            status="${?}"
            # Guard against "Error: stepping, database is locked (5)"
            if [ "${status}" = '5' ]; then
                sleep 1
                continue
            fi
        }
        if [ "${status}" -eq '0' ]; then
            break
        fi
        if [ "${i}" -ge '3' ] && [ "${status}" -ne '0' ]; then
            printf '%s [ERROR]: There was an error during SQL command %s\n' "$(date "${datetime_format}")" "${command}" >&2
            exit "${status}"
        fi
    done
}

# Detect or create database
if [ -e '/etc/pihole/gravity.db' ]; then
    printf '%s [INFO]: Database found\n' "$(date "${datetime_format}")" >&2
else
    printf '%s [INFO]: Database created\n' "$(date "${datetime_format}")" >&2
    pihole updateGravity
fi

# Wait for database tables to be ready
while true; do
    count="$(sql "SELECT count(*) FROM [sqlite_master] WHERE type='table' AND name='gravity';")"
    if [ "${count}" -gt '0' ]; then
        break
    fi
    printf '%s [INFO]: Waiting for database tables\n' "$(date "${datetime_format}")" >&2
    sleep 1
done
printf '%s [INFO]: Main table found\n' "$(date "${datetime_format}")" >&2

# Wipe other existing entities
sql 'DELETE FROM [adlist_by_group];'
sql 'DELETE FROM [gravity];'
sql 'DELETE FROM [adlist];'
sql 'DELETE FROM [domainlist];'

# Ban all domains
sql "INSERT INTO [domainlist] (type, domain, enabled, date_added, date_modified, comment) VALUES (3, '.*', 1, 0, 0, '');"

# Restart DNS
pihole reloaddns

# FTL starts as an unprivileged user, so apply the FTLCONF_* variables while this
# setup script is running as root. This also persists the API password hash.
pihole-FTL --config dns.blocking.active true

# Make sure all subdirectories are owned by homelab user
chown -R homelab:homelab '/etc/pihole'
