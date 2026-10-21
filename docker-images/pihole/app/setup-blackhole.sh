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
    printf '%s\n' "${*}" | while IFS= read -r log_message; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

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
            log ERROR "$(printf 'There was an error during SQL command %s' "${command}")"
            exit "${status}"
        fi
    done
}

# Detect or create database
if [ -e '/etc/pihole/gravity.db' ]; then
    log INFO 'Database found'
else
    log INFO 'Database created'
    pihole updateGravity
fi

# Wait for database tables to be ready
while true; do
    count="$(sql "SELECT count(*) FROM [sqlite_master] WHERE type='table' AND name='gravity';")"
    if [ "${count}" -gt '0' ]; then
        break
    fi
    log INFO 'Waiting for database tables'
    sleep 1
done
log INFO 'Main table found'

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
