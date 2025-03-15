#!/bin/sh
set -euf

# Set custom local domains
custom_domains="[$(sed -E 's~#.*$~~;s~  ~ ~g;s~^ +~~;s~ +$~~' </homelab/custom-domains.txt | grep -vE '^ *$' | sed -E 's~^(.*)$~"\1"~' | tr '\n' ',' | sed -E 's~,$~~;s~,~, ~g')]"
printf 'Custom domains: %s\n' "$custom_domains"
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
    count="$(pihole-FTL sqlite3 /etc/pihole/gravity.db "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='gravity';")"
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
pihole-FTL sqlite3 /etc/pihole/gravity.db 'DELETE FROM client_by_group;'
pihole-FTL sqlite3 /etc/pihole/gravity.db 'DELETE FROM [group] WHERE id!=0;'
pihole-FTL sqlite3 /etc/pihole/gravity.db 'DELETE FROM client;'

# Add custom open group
default_group_id='0'
pihole-FTL sqlite3 /etc/pihole/gravity.db "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'Open', 0, 0, 'The group without adblocking');"
open_group_id="$(pihole-FTL sqlite3 /etc/pihole/gravity.db "SELECT id FROM [group] WHERE name='Open';")"

# Custom clients
unbound_default_1_ip='10.1.10.1'
pihole-FTL sqlite3 /etc/pihole/gravity.db "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_default_1_ip', 0, 0, 'Unbound 1 default');"
unbound_default_1_id="$(pihole-FTL sqlite3 /etc/pihole/gravity.db "SELECT id FROM client WHERE ip='$unbound_default_1_ip';")"
unbound_open_1_ip='10.1.10.2'
pihole-FTL sqlite3 /etc/pihole/gravity.db "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_open_1_ip', 0, 0, 'Unbound 1 open');"
unbound_open_1_id="$(pihole-FTL sqlite3 /etc/pihole/gravity.db "SELECT id FROM client WHERE ip='$unbound_open_1_ip';")"
unbound_default_2_ip='10.1.16.1'
pihole-FTL sqlite3 /etc/pihole/gravity.db "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_default_2_ip', 0, 0, 'Unbound 2 default');"
unbound_default_2_id="$(pihole-FTL sqlite3 /etc/pihole/gravity.db "SELECT id FROM client WHERE ip='$unbound_default_2_ip';")"
unbound_open_2_ip='10.1.16.2'
pihole-FTL sqlite3 /etc/pihole/gravity.db "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_open_2_ip', 0, 0, 'Unbound 2 open');"
unbound_open_2_id="$(pihole-FTL sqlite3 /etc/pihole/gravity.db "SELECT id FROM client WHERE ip='$unbound_open_2_ip';")"

# Assign clients to groups
pihole-FTL sqlite3 /etc/pihole/gravity.db "UPDATE client_by_group SET group_id=$default_group_id WHERE client_id=$unbound_default_1_id;"
pihole-FTL sqlite3 /etc/pihole/gravity.db "UPDATE client_by_group SET group_id=$default_group_id WHERE client_id=$unbound_default_2_id;"
pihole-FTL sqlite3 /etc/pihole/gravity.db "UPDATE client_by_group SET group_id=$open_group_id WHERE client_id=$unbound_open_1_id;"
pihole-FTL sqlite3 /etc/pihole/gravity.db "UPDATE client_by_group SET group_id=$open_group_id WHERE client_id=$unbound_open_2_id;"
