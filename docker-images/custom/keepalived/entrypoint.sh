#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

setup_keepalived() {
    cat '/etc/keepalived/keepalived.conf' |
        sed "s~@appname@~$KEEPALIVED_APPNAME~g" |
        sed "s~@state@~$KEEPALIVED_STATE~g" |
        sed "s~@networkinterface@~$KEEPALIVED_NETWORK_INTERFACE~g" |
        sed "s~@currentip@~$KEEPALIVED_CURRENT_IP~g" |
        sed "s~@otherip@~$KEEPALIVED_OTHER_IP~g" |
        sed "s~@priority@~$KEEPALIVED_PRIORITY~g" |
        sed "s~@password@~$KEEPALIVED_PASSWORD~g" |
        sed "s~@virtualip@~$KEEPALIVED_VIRTUAL_IP~g" |
        sponge '/etc/keepalived/keepalived.conf'

    printf 'Keepalived config:\n'
    cat '/etc/keepalived/keepalived.conf'
    printf '%s' '---\n'
}

if [ "${KEEPALIVED_SKIP-0}" = '1' ]; then
    printf 'Skipping keepalived\n'
    printf 'started\n' >/homelab/.internal/status.txt
    while true; do
        sleep infinity
        printf '"sleep infinity" somehow exited?' >&2
    done
else
    printf 'Setting up keepalived\n'
    setup_keepalived
    printf 'started\n' >/homelab/.internal/status.txt
fi

# printf 'Starting keepalived\n'
# which keepalived

# statusfile='/homelab/status.txt'
# logfile='/homelab/output.log'
# (keepalived --dump-conf --log-console --log-detail --vrrp || printf '%s\n' "$?" >"$statusfile") | tee "$logfile"

# printf 'Status: %s\n' "$(cat "$statusfile")"
# printf 'Log 1: %s\n' "$(cat "$logfile")"
# printf 'Log 2: %s\n' "$(cat '/tmp/keepalived')"
# printf 'Log 3: %s\n' "$(cat '/tmp/keepalived.data')"

keepalived --dont-fork --dump-conf --log-console --log-detail --vrrp &

printf 'started\n' >/homelab/.internal/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
