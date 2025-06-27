#!/bin/sh
set -euf

sql() {
    command="$1"
    i=0
    while [ "$i" -lt '3' ]; do
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

# Set custom local domains
custom_domains="[$(sed -E 's~#.*$~~;s~  ~ ~g;s~^ +~~;s~ +$~~' </homelab/custom-domains.txt | grep -vE '^ *$' | sed -E 's~^(.*)$~"\1"~' | tr '\n' ',' | sed -E 's~,$~~;s~,~, ~g')]"
pihole-FTL --config dns.hosts "$custom_domains"

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
sql 'DELETE FROM client_by_group;'
sql 'DELETE FROM [group] WHERE id!=0;'
sql 'DELETE FROM client;'

# Add custom open group
default_group_id='0'
sql "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'Open', 0, 0, 'The group without adblocking');"
open_group_id="$(sql "SELECT id FROM [group] WHERE name='Open';")"
all_groups="$(printf '%s\n%s\n' "$default_group_id" "$open_group_id")"

# Custom allowlists and blocklists
sql 'DELETE FROM domainlist_by_group;'
sql 'DELETE FROM domainlist;'
local_domains="$(sed -E 's~#.*$~~;s~  ~ ~g;s~^ +~~;s~ +$~~;s~^.+ +~~' </homelab/custom-domains.txt | grep -vE '^ *$' | grep -E '^.+\.home\.matejkosiarcik\.com$' | sed 's~.home.matejkosiarcik.com~~;s~\.~\\.~g;s~\-~\\-~g' | tr '\n' '|' | sed -E 's~^(.+)\|$~^(\1)\.home\.matejkosiarcik\.com$~')"
sql "INSERT INTO domainlist (type, domain, enabled, date_added, date_modified, comment) VALUES (2, '$local_domains', 1, 0, 0, '');"
sql "INSERT INTO domainlist (type, domain, enabled, date_added, date_modified, comment) VALUES (3, '^.*\.home\.matejkosiarcik\.com$', 1, 0, 0, '');"
printf '%s\n' "$all_groups" | while read -r group; do
    if [ "$group" = "$default_group_id" ]; then continue; fi
    sql "INSERT INTO domainlist_by_group (domainlist_id, group_id) SELECT id, $group FROM domainlist;"
done

# Custom clients
unbound_default_1_ip='10.1.10.1'
sql "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_default_1_ip', 0, 0, 'Unbound 1 default');"
unbound_default_1_id="$(sql "SELECT id FROM client WHERE ip='$unbound_default_1_ip';")"
unbound_open_1_ip='10.1.10.2'
sql "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_open_1_ip', 0, 0, 'Unbound 1 open');"
unbound_open_1_id="$(sql "SELECT id FROM client WHERE ip='$unbound_open_1_ip';")"
unbound_default_2_ip='10.1.16.1'
sql "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_default_2_ip', 0, 0, 'Unbound 2 default');"
unbound_default_2_id="$(sql "SELECT id FROM client WHERE ip='$unbound_default_2_ip';")"
unbound_open_2_ip='10.1.16.2'
sql "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_open_2_ip', 0, 0, 'Unbound 2 open');"
unbound_open_2_id="$(sql "SELECT id FROM client WHERE ip='$unbound_open_2_ip';")"

# Assign clients to groups
sql "UPDATE client_by_group SET group_id=$default_group_id WHERE client_id=$unbound_default_1_id;"
sql "UPDATE client_by_group SET group_id=$default_group_id WHERE client_id=$unbound_default_2_id;"
sql "UPDATE client_by_group SET group_id=$open_group_id WHERE client_id=$unbound_open_1_id;"
sql "UPDATE client_by_group SET group_id=$open_group_id WHERE client_id=$unbound_open_2_id;"

# Configuration workaround for homepage
sessions=32
thread=6
# if [ "$(uname -m)" = 'x86_64' ]; then
#     sessions=64
#     thread=16
# fi
pihole-FTL --config webserver.api.max_sessions "$sessions"
pihole-FTL --config webserver.threads "$threads"

# Restart DNS
pihole reloaddns
