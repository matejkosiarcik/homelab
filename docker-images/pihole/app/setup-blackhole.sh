#!/bin/sh
set -euf

sql() {
    command="${1}"
    i=0
    while [ "${i}" -le '3' ]; do
        i="$((i + 1))"
        status='0'
        pihole-FTL sqlite3 '/etc/pihole/gravity.db' "${command}" || {
            status="$?"
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
            printf 'There was an error during SQL command %s\n' "${command}" >&2
            exit "${status}"
        fi
    done
}

# Detect or create database
if [ -e '/etc/pihole/gravity.db' ]; then
    printf 'Database found\n'
else
    printf 'Database created\n'
    pihole updateGravity
fi

# Wait for database tables to be ready
while true; do
    count="$(sql "SELECT count(*) FROM [sqlite_master] WHERE type='table' AND name='gravity';")"
    if [ "${count}" -gt '0' ]; then
        break
    fi
    printf 'Waiting for database tables\n'
    sleep 1
done
printf 'Main table found\n'

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
