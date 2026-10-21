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
    printf '%s\n' "${*}" | while IFS= read -r log_message || [ -n "${log_message}" ]; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}
# This script sets up macvlan-shim "router" to be able to access containers running in macvlan network from current host

if [ "${#}" -lt 2 ]; then
    log ERROR 'Not enough arguments'
    exit 1
fi

id="${1}"
external_ip="${2}"

# Get appropriate network interface
found_interface=''
if [ "${found_interface}" = '' ]; then
    found_interface="$( ( (ip link show eth0 >'/dev/null' 2>'/dev/null') && printf 'eth0') || true)"
fi
if [ "${found_interface}" = '' ]; then
    found_interface="$( ( (ip link show enp1s0 >'/dev/null' 2>'/dev/null') && printf 'enp1s0') || true)"
fi
if [ "${found_interface}" = '' ]; then
    found_interface="$( ( (ip link show enp1s0f0 >'/dev/null' 2>'/dev/null') && printf 'enp1s0f0') || true)"
fi

if [ "${found_interface}" = '' ]; then
    log ERROR 'No suitable network interface found'
    exit 1
fi

# printf 'Found network interface %s\n' "${found_interface}"

router_name="ethbr-${id}"
sudo ip link add link "${found_interface}" name "${router_name}" type bridge
sudo ip address add "${external_ip}/32" dev "${router_name}"
sudo ip link set "${router_name}" up
