#!/bin/sh
set -euf

sql() {
    command="${1}"
    i=0
    while [ "${i}" -le '3' ]; do
        i="$((i + 1))"
        status='0'
        pihole-FTL sqlite3 /etc/pihole/gravity.db "${command}" || {
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
sql 'DELETE FROM [client_by_group];'
sql 'DELETE FROM [group] WHERE id!=0;'
sql 'DELETE FROM [client];'

# Add custom open group
default_group_id='0'
sql "UPDATE [group] SET name='Default', description='Default group' WHERE id='${default_group_id}';"
sql "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'Adfull', 0, 0, 'Custom group without adblocking');"
adfull_group_id="$(sql "SELECT id FROM [group] WHERE name='Adfull';")"

# Custom clients
unbound_default_1_ip='10.1.12.1'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_default_1_ip}', 0, 0, 'Unbound 1 Default');"
unbound_default_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_default_1_ip}';")"

unbound_matej_1_ip='10.1.12.2'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_matej_1_ip}', 0, 0, 'Unbound 1 Matej');"
unbound_matej_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_matej_1_ip}';")"

unbound_monika_1_ip='10.1.12.3'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_monika_1_ip}', 0, 0, 'Unbound 1 Monika');"
unbound_monika_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_monika_1_ip}';")"

unbound_iot_1_ip='10.1.12.4'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_iot_1_ip}', 0, 0, 'Unbound 1 IoT');"
unbound_iot_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_iot_1_ip}';")"

unbound_guests_1_ip='10.1.12.5'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_guests_1_ip}', 0, 0, 'Unbound 1 Guests');"
unbound_guests_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_guests_1_ip}';")"

unbound_internal_1_ip='10.1.12.6'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_internal_1_ip}', 0, 0, 'Unbound 1 Internal');"
unbound_internal_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_internal_1_ip}';")"

unbound_blackhole_1_ip='10.1.12.7'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_blackhole_1_ip}', 0, 0, 'Unbound 1 Blackhole');"
unbound_blackhole_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_blackhole_1_ip}';")"

unbound_default_2_ip='10.1.10.1'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_default_2_ip}', 0, 0, 'Unbound 2 Default');"
unbound_default_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_default_2_ip}';")"

unbound_matej_2_ip='10.1.10.2'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_matej_2_ip}', 0, 0, 'Unbound 2 Matej');"
unbound_matej_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_matej_2_ip}';")"

unbound_monika_2_ip='10.1.10.3'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_monika_2_ip}', 0, 0, 'Unbound 2 Monika');"
unbound_monika_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_monika_2_ip}';")"

unbound_iot_2_ip='10.1.10.4'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_iot_2_ip}', 0, 0, 'Unbound 2 IoT');"
unbound_iot_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_iot_2_ip}';")"

unbound_guests_2_ip='10.1.10.5'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_guests_2_ip}', 0, 0, 'Unbound 2 Guests');"
unbound_guests_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_guests_2_ip}';")"

unbound_internal_2_ip='10.1.10.6'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_internal_2_ip}', 0, 0, 'Unbound 2 Internal');"
unbound_internal_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_internal_2_ip}';")"

unbound_blackhole_2_ip='10.1.10.7'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_blackhole_2_ip}', 0, 0, 'Unbound 2 Blackhole');"
unbound_blackhole_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_blackhole_2_ip}';")"

# Assign clients to groups
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_default_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_default_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_matej_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_matej_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${adfull_group_id}' WHERE client_id='${unbound_monika_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${adfull_group_id}' WHERE client_id='${unbound_monika_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_iot_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_iot_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_guests_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_guests_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_internal_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_internal_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_blackhole_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_blackhole_2_id}';"

# Set custom local domains
custom_domains_a="[ $(sed -E 's~#.*$~~;s~  ~ ~g;s~^ +~~;s~ +$~~' </homelab/custom-domains.txt | grep -vE '^ *$' | grep -E '^[0-9]' | sed -E 's~^(.*)$~"\1"~' | tr '\n' ',' | sed -E 's~,$~~;s~,~, ~g') ]"
pihole-FTL --config dns.hosts "${custom_domains_a}"
custom_domains_cname="[ $(sed -E 's~#.*$~~;s~  ~ ~g;s~^ +~~;s~ +$~~' </homelab/custom-domains.txt | grep -vE '^ *$' | grep -E '^[a-zA-Z]' | sed -E 's~^(.*) (.*)$~"\1,\2"~' | tr '\n' ',' | sed -E 's~,$~~;s~,~, ~g') ]"
pihole-FTL --config dns.cnameRecords "${custom_domains_cname}"

# Restart DNS
pihole reloaddns

# FTL starts as an unprivileged user, so apply the FTLCONF_* variables while this
# setup script is running as root. This also persists the API password hash.
pihole-FTL --config dns.blocking.active true

# Make sure all subdirectories are owned by homelab user
chown -R homelab:homelab /etc/pihole
