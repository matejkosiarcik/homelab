#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

# Clean lists before making changes
printf 'Wipe existing blacklists and whitelists\n'
pihole whitelist --nuke
pihole --white-wild --nuke
pihole --white-regex --nuke
pihole blacklist --nuke
pihole --wild --nuke
pihole --regex --nuke

# Update whitelist
sed -E 's~#.*$~~' <'/homelab/domains-whitelist.txt' | grep -E '.+' | while read -r entry; do
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
sed -E 's~#.*$~~' <'/homelab/domains-blacklist.txt' | grep -E '.+' | while read -r entry; do
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

# TODO: Setup custom adlists too

printf 'started\n' >/homelab/.internal/status.txt
sleep infinity
