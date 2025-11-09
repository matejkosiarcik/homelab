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
    count="$(sql "SELECT count(*) FROM [sqlite_master] WHERE type='table' AND name='gravity';")"
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
sql 'DELETE FROM [client_by_group];'
sql 'DELETE FROM [group] WHERE id!=0;'
sql 'DELETE FROM [client];'

# Add custom open group
default_group_id='0'
sql "UPDATE [group] SET name='Default', description='Default group' WHERE id='$default_group_id';"
sql "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'Adfull', 0, 0, 'Custom group without adblocking');"
adfull_group_id="$(sql "SELECT id FROM [group] WHERE name='Adfull';")"

# Custom clients
unbound_default_1_ip='10.1.12.1'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_default_1_ip', 0, 0, 'Unbound 1 Default');"
unbound_default_1_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_default_1_ip';")"

unbound_matej_1_ip='10.1.12.2'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_matej_1_ip', 0, 0, 'Unbound 1 Matej');"
unbound_matej_1_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_matej_1_ip';")"

unbound_monika_1_ip='10.1.12.3'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_monika_1_ip', 0, 0, 'Unbound 1 Monika');"
unbound_monika_1_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_monika_1_ip';")"

unbound_iot_1_ip='10.1.12.4'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_iot_1_ip', 0, 0, 'Unbound 1 IoT');"
unbound_iot_1_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_iot_1_ip';")"

unbound_guests_1_ip='10.1.12.5'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_guests_1_ip', 0, 0, 'Unbound 1 Guests');"
unbound_guests_1_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_guests_1_ip';")"

unbound_internal_1_ip='10.1.12.6'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_internal_1_ip', 0, 0, 'Unbound 1 Internal');"
unbound_internal_1_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_internal_1_ip';")"

unbound_blackhole_1_ip='10.1.12.7'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_blackhole_1_ip', 0, 0, 'Unbound 1 Blackhole');"
unbound_blackhole_1_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_blackhole_1_ip';")"

unbound_default_2_ip='10.1.10.1'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_default_2_ip', 0, 0, 'Unbound 2 Default');"
unbound_default_2_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_default_2_ip';")"

unbound_matej_2_ip='10.1.10.2'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_matej_2_ip', 0, 0, 'Unbound 2 Matej');"
unbound_matej_2_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_matej_2_ip';")"

unbound_monika_2_ip='10.1.10.3'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_monika_2_ip', 0, 0, 'Unbound 2 Monika');"
unbound_monika_2_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_monika_2_ip';")"

unbound_iot_2_ip='10.1.10.4'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_iot_2_ip', 0, 0, 'Unbound 2 IoT');"
unbound_iot_2_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_iot_2_ip';")"

unbound_guests_2_ip='10.1.10.5'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_guests_2_ip', 0, 0, 'Unbound 2 Guests');"
unbound_guests_2_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_guests_2_ip';")"

unbound_internal_2_ip='10.1.10.6'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_internal_2_ip', 0, 0, 'Unbound 2 Internal');"
unbound_internal_2_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_internal_2_ip';")"

unbound_blackhole_2_ip='10.1.10.7'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('$unbound_blackhole_2_ip', 0, 0, 'Unbound 2 Blackhole');"
unbound_blackhole_2_id="$(sql "SELECT id FROM [client] WHERE ip='$unbound_blackhole_2_ip';")"

# Assign clients to groups
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_default_1_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_default_2_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_matej_1_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_matej_2_id';"
sql "UPDATE [client_by_group] SET group_id='$adfull_group_id' WHERE client_id='$unbound_monika_1_id';"
sql "UPDATE [client_by_group] SET group_id='$adfull_group_id' WHERE client_id='$unbound_monika_2_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_iot_1_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_iot_2_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_guests_1_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_guests_2_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_internal_1_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_internal_2_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_blackhole_1_id';"
sql "UPDATE [client_by_group] SET group_id='$default_group_id' WHERE client_id='$unbound_blackhole_2_id';"

# Set custom local domains
custom_domains="[$(sed -E 's~#.*$~~;s~  ~ ~g;s~^ +~~;s~ +$~~' </homelab/custom-domains.txt | grep -vE '^ *$' | sed -E 's~^(.*)$~"\1"~' | tr '\n' ',' | sed -E 's~,$~~;s~,~, ~g')]"
pihole-FTL --config dns.hosts "$custom_domains"

# Restart DNS
pihole reloaddns
