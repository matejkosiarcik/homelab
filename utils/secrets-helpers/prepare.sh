#!/bin/sh
set -euf

online_mode='online'
mode=''
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d | --dev)
        mode='dev'
        shift
        ;;
    -p | --prod)
        mode='prod'
        shift
        ;;
    --online)
        online_mode='online'
        shift
        ;;
    --offline)
        online_mode='offline'
        shift
        ;;
    *)
        printf 'Unknown argument %s\n' "$1"
        exit 1
        ;;
    esac
done

if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
    if [ "${BW_SESSION-}" = '' ]; then
        echo 'You must set BW_SESSION env variable before calling this script.' >&2
        exit 1
    fi
fi

if [ "$mode" = 'prod' ] || [ "$online_mode" = 'online' ]; then
    bw sync                  # Sync latest changes
    bw list items >/dev/null # Verify we can access Vaultwarden
fi
