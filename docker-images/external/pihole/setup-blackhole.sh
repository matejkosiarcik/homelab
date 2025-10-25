#!/bin/sh
set -euf

sql() {
    command="$1"
    i=0
    while [ "$i" -le '3' ]; do
        i="$((i + 1))"
        status='0'
        pihole-FTL sqlite3 /etc/pihole/gravity.db "$command" || {
            status="$?"
            # Guard against "Error: stepping, database is locked (5)"
            if [ "$status" = '5' ]; then
                sleep 1
                continue
            fi
        }
        if [ "$status" -eq '0' ]; then
            break
        fi
        if [ "$i" -ge '3' ] && [ "$status" -ne '0' ]; then
            printf 'There was an error during SQL command %s\n' "$command" >&2
            exit "$status"
        fi
    done
}

# Wait for database to exist
db_log='0'
while [ ! -e '/etc/pihole/gravity.db' ]; do
    if [ "$db_log" -eq '0' ]; then
        db_log='1'
        printf 'Waiting for database\n'
    fi
    sleep 1
done
printf 'Database found\n'

# Wait for database tables to be ready
db_log='0'
while true; do
    count="$(sql "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='gravity';")"
    if [ "$count" -gt '0' ]; then
        break
    fi
    if [ "$db_log" -eq '0' ]; then
        db_log='1'
        printf 'Waiting for database table\n'
    fi
    sleep 1
done
printf 'Main table found\n'

# Wipe other existing entities
sql 'DELETE FROM [adlist_by_group];'
sql 'DELETE FROM [gravity];'
sql 'DELETE FROM [adlist];'

# Ban all domains
sql "INSERT INTO [domainlist] (type, domain, enabled, date_added, date_modified, comment) VALUES (3, '.*', 1, 0, 0, '');"

# Restart DNS
pihole reloaddns
