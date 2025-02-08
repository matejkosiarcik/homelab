#!/bin/sh
set -euf

db_log='0'
while [ ! -e '/etc/pihole/gravity.db' ]; do
    if [ "$db_log" -eq '0' ]; then
        db_log='1'
        printf 'Waiting for database\n'
    fi
    sleep 1
done
printf 'Database found\n'

db_log='0'
while true; do
    count="$(sqlite3 /etc/pihole/gravity.db 'SELECT count(*) FROM sqlite_master WHERE type="table" AND name="gravity";')"
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

# Clean custom lists before making changes
printf 'Wipe existing blacklists and whitelists\n'
pihole whitelist --nuke
pihole --white-wild --nuke
pihole --white-regex --nuke
pihole blacklist --nuke
pihole --wild --nuke
pihole --regex --nuke

# Wipe other existing entities
sqlite3 /etc/pihole/gravity.db 'DELETE FROM adlist;'
sqlite3 /etc/pihole/gravity.db 'DELETE FROM client;'
sqlite3 /etc/pihole/gravity.db 'DELETE FROM client_by_group;'
sqlite3 /etc/pihole/gravity.db 'DELETE FROM [group] WHERE id!=0;'
sqlite3 /etc/pihole/gravity.db 'DELETE FROM domainlist_by_group WHERE group_id!=0;'

# Update whitelist
# Note: Only applies to default group
sed -E 's~#.*$~~' <'/homelab/domains-whitelist.txt' | (grep -E '.+' || true) | while read -r entry; do
    domain="$(printf '%s' "$entry" | sed -E 's~ .*$~~')"
    if (printf '%s' "$entry" | grep -- '\[wildcard\]' >/dev/null 2>&1); then
        printf 'Add whitelist [wildcard]: %s\n' "$domain"
        pihole --white-wild --noreload "$domain"
    elif (printf '%s' "$entry" | grep -- '\[regex\]' >/dev/null 2>&1); then
        printf 'Add whitelist [regex]: %s\n' "$domain"
        pihole --white-regex --noreload "$domain"
    else
        printf 'Add whitelist [exact]: %s\n' "$domain"
        pihole whitelist --noreload "$domain"
    fi
done

# Update blacklist
# Note: Only applies to default group
sed -E 's~#.*$~~' <'/homelab/domains-blacklist.txt' | (grep -E '.+' || true) | while read -r entry; do
    domain="$(printf '%s' "$entry" | sed -E 's~ .*$~~')"
    if (printf '%s' "$entry" | grep -- '\[wildcard\]' >/dev/null 2>&1); then
        printf 'Add blacklist [wildcard]: %s\n' "$domain"
        pihole --wild --noreload "$domain"
    elif (printf '%s' "$entry" | grep -- '\[regex\]' >/dev/null 2>&1); then
        printf 'Add blacklist [regex]: %s\n' "$domain"
        pihole --regex --noreload "$domain"
    else
        printf 'Add blacklist [exact]: %s\n' "$domain"
        pihole blacklist --noreload "$domain"
    fi
done

# Add custom open group
default_group_id='0'
sqlite3 /etc/pihole/gravity.db "INSERT INTO [group] (enabled, name, date_added, date_modified, description) VALUES (1, 'Open', 0, 0, 'The group without adblocking');"
open_group_id="$(sqlite3 /etc/pihole/gravity.db "SELECT id FROM [group] WHERE name='Open';")"

# Custom clients
unbound_default_1_ip='10.1.10.1'
sqlite3 /etc/pihole/gravity.db "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_default_1_ip', 0, 0, 'Unbound 1 default');"
unbound_default_1_id="$(sqlite3 /etc/pihole/gravity.db "SELECT id FROM client WHERE ip='$unbound_default_1_ip';")"
unbound_open_1_ip='10.1.10.2'
sqlite3 /etc/pihole/gravity.db "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_open_1_ip', 0, 0, 'Unbound 1 open');"
unbound_open_1_id="$(sqlite3 /etc/pihole/gravity.db "SELECT id FROM client WHERE ip='$unbound_open_1_ip';")"
unbound_default_2_ip='10.1.16.1'
sqlite3 /etc/pihole/gravity.db "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_default_2_ip', 0, 0, 'Unbound 2 default');"
unbound_default_2_id="$(sqlite3 /etc/pihole/gravity.db "SELECT id FROM client WHERE ip='$unbound_default_2_ip';")"
unbound_open_2_ip='10.1.16.2'
sqlite3 /etc/pihole/gravity.db "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('$unbound_open_2_ip', 0, 0, 'Unbound 2 open');"
unbound_open_2_id="$(sqlite3 /etc/pihole/gravity.db "SELECT id FROM client WHERE ip='$unbound_open_2_ip';")"

# Assign clients to groups
sqlite3 /etc/pihole/gravity.db "UPDATE client_by_group SET group_id=$default_group_id WHERE client_id=$unbound_default_1_id;"
sqlite3 /etc/pihole/gravity.db "UPDATE client_by_group SET group_id=$default_group_id WHERE client_id=$unbound_default_2_id;"
sqlite3 /etc/pihole/gravity.db "UPDATE client_by_group SET group_id=$open_group_id WHERE client_id=$unbound_open_1_id;"
sqlite3 /etc/pihole/gravity.db "UPDATE client_by_group SET group_id=$open_group_id WHERE client_id=$unbound_open_2_id;"

# Custom adlists
sed -E 's~#.*$~~' <'/homelab/adlists-default.txt' | (grep -E '.+' || true) | while read -r entry; do
    adlist="$(printf '%s' "$entry" | sed -E 's~ .*$~~')"
    sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('$adlist', 1, 'custom');"
    # Adlists are automatically assigned to default group
done

# Assign whitelist+blacklist domains also to secondary group
sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist_by_group (domainlist_id, group_id) SELECT domainlist_id, $open_group_id FROM domainlist_by_group WHERE group_id=$default_group_id;"

# Update gravity after changing adlists
pihole updateGravity
