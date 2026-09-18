#!/bin/sh
set -euf

if [ "${#}" -eq 0 ]; then
    exit 0
fi

# Intentionally fail for this capability to avoid starting DHCP
if [ "${1}" = '--has-p=cap_net_admin' ]; then
    exit 1
fi

# Succeed for other capabilities
if [ "${#}" -eq 1 ]; then
    exit 0
fi

while [ "${#}" -gt 0 ]; do
    if [ "${1}" = '--' ]; then
        shift
        break
    fi
    shift
done

if [ "${1-}" = '-c' ] && [ "${#}" -ge 2 ]; then
    shift
    exec /bin/sh -c "${@}"
fi

exit 0
