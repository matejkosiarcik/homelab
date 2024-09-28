#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

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
    count="$(sqlite3 /etc/pihole/gravity.db 'SELECT count(*) FROM sqlite_master WHERE type="table" AND name="main.gravity";')"
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

# Clean lists before making changes
printf 'Wipe existing blacklists and whitelists\n'
pihole whitelist --nuke
pihole --white-wild --nuke
pihole --white-regex --nuke
pihole blacklist --nuke
pihole --wild --nuke
pihole --regex --nuke

# Update whitelist
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

# Custom adlists
sqlite3 /etc/pihole/gravity.db 'DELETE FROM adlist;'
sed -E 's~#.*$~~' <'/homelab/adlists.txt' | (grep -E '.+' || true) | while read -r entry; do
    adlist="$(printf '%s' "$entry" | sed -E 's~ .*$~~')"
    echo "New adlist: $adlist"
    sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('$adlist', 1, 'custom');"
done

# Update gravity after changing adlists
pihole updateGravity

printf 'started\n' >/homelab/.internal/status.txt
sleep infinity
