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
    log INFO 'Creating database'
    pihole updateGravity
    log INFO 'Database created'
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

setup_db_date="$(date '+%s')"

# Wipe other existing entities
sql 'DELETE FROM [client_by_group];'
sql 'DELETE FROM [group] WHERE id!=0;'
sql 'DELETE FROM [client];'

# Add custom groups
default_group_id='0'
sql "UPDATE [group] SET name='Default', date_modified=${setup_db_date}, description='Default group' WHERE id='${default_group_id}';"
sql "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'Monika', ${setup_db_date}, ${setup_db_date}, 'Custom group without adblocking');"
monika_group_id="$(sql "SELECT id FROM [group] WHERE name='Monika';")"
sql "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'Matej', ${setup_db_date}, ${setup_db_date}, 'Custom group with default policies');"
matej_group_id="$(sql "SELECT id FROM [group] WHERE name='Matej';")"
sql "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'IoT', ${setup_db_date}, ${setup_db_date}, 'Custom group with default policies');"
iot_group_id="$(sql "SELECT id FROM [group] WHERE name='IoT';")"
sql "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'Guests', ${setup_db_date}, ${setup_db_date}, 'Custom group with default policies');"
guests_group_id="$(sql "SELECT id FROM [group] WHERE name='Guests';")"
sql "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'Blackhole', ${setup_db_date}, ${setup_db_date}, 'Custom group with default policies');"
blackhole_group_id="$(sql "SELECT id FROM [group] WHERE name='Blackhole';")"
sql "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'App', ${setup_db_date}, ${setup_db_date}, 'Custom group with default policies');"
app_group_id="$(sql "SELECT id FROM [group] WHERE name='App';")"

# Copy default policies to these groups to keep default settings (adblocking enabled)
for group_id in "${matej_group_id}" "${iot_group_id}" "${guests_group_id}" "${blackhole_group_id}" "${app_group_id}"; do
    sql "INSERT INTO [adlist_by_group] (adlist_id, group_id) SELECT adlist_id, '${group_id}' FROM [adlist_by_group] WHERE group_id='${default_group_id}';"
    sql "INSERT INTO [domainlist_by_group] (domainlist_id, group_id) SELECT domainlist_id, '${group_id}' FROM [domainlist_by_group] WHERE group_id='${default_group_id}';"
done

# Custom clients
unbound_default_1_ip='10.1.12.1'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_default_1_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Default-1');"
unbound_default_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_default_1_ip}';")"

unbound_matej_1_ip='10.1.12.2'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_matej_1_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Matej-1');"
unbound_matej_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_matej_1_ip}';")"

unbound_monika_1_ip='10.1.12.3'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_monika_1_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Monika-1');"
unbound_monika_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_monika_1_ip}';")"

unbound_iot_1_ip='10.1.12.4'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_iot_1_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-IoT-1');"
unbound_iot_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_iot_1_ip}';")"

unbound_guests_1_ip='10.1.12.5'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_guests_1_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Guests-1');"
unbound_guests_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_guests_1_ip}';")"

unbound_internal_1_ip='10.1.12.6'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_internal_1_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Internal-1');"
unbound_internal_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_internal_1_ip}';")"

unbound_blackhole_1_ip='10.1.12.7'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_blackhole_1_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Blackhole-1');"
unbound_blackhole_1_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_blackhole_1_ip}';")"

unbound_default_2_ip='10.1.10.1'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_default_2_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Default-2');"
unbound_default_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_default_2_ip}';")"

unbound_matej_2_ip='10.1.10.2'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_matej_2_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Matej-2');"
unbound_matej_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_matej_2_ip}';")"

unbound_monika_2_ip='10.1.10.3'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_monika_2_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Monika-2');"
unbound_monika_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_monika_2_ip}';")"

unbound_iot_2_ip='10.1.10.4'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_iot_2_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-IoT-2');"
unbound_iot_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_iot_2_ip}';")"

unbound_guests_2_ip='10.1.10.5'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_guests_2_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Guests-2');"
unbound_guests_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_guests_2_ip}';")"

unbound_internal_2_ip='10.1.10.6'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_internal_2_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Internal-2');"
unbound_internal_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_internal_2_ip}';")"

unbound_blackhole_2_ip='10.1.10.7'
sql "INSERT INTO [client] (ip, date_added, date_modified, comment) VALUES ('${unbound_blackhole_2_ip}', ${setup_db_date}, ${setup_db_date}, 'Unbound-Blackhole-2');"
unbound_blackhole_2_id="$(sql "SELECT id FROM [client] WHERE ip='${unbound_blackhole_2_ip}';")"

# Assign clients to groups
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_default_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_default_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${matej_group_id}' WHERE client_id='${unbound_matej_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${matej_group_id}' WHERE client_id='${unbound_matej_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${monika_group_id}' WHERE client_id='${unbound_monika_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${monika_group_id}' WHERE client_id='${unbound_monika_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${iot_group_id}' WHERE client_id='${unbound_iot_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${iot_group_id}' WHERE client_id='${unbound_iot_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${guests_group_id}' WHERE client_id='${unbound_guests_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${guests_group_id}' WHERE client_id='${unbound_guests_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_internal_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${default_group_id}' WHERE client_id='${unbound_internal_2_id}';"
sql "UPDATE [client_by_group] SET group_id='${blackhole_group_id}' WHERE client_id='${unbound_blackhole_1_id}';"
sql "UPDATE [client_by_group] SET group_id='${blackhole_group_id}' WHERE client_id='${unbound_blackhole_2_id}';"

# Set custom FTL config
find '/homelab/config/FTL' -mindepth 1 -maxdepth 1 -type f | while read -r file; do
    printf 'Setting pihole-FTL config: %s\n' "$(basename "${file}" .txt)"
    pihole-FTL --config "$(basename "${file}" .txt)" "$(cat "${file}")"
done

# Reload group policies and restart DNS
pihole reloadlists
pihole reloaddns

# Update and resolve current version
pihole updatechecker

# Make sure all subdirectories are owned by homelab user
chown -R homelab:homelab '/etc/pihole'
