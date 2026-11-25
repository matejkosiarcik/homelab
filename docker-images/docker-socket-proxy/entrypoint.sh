#!/bin/sh
set -euf

haproxy_pid=''
stunnel_pid=''

stop_children() {
    trap - TERM INT

    for child_pid in "${haproxy_pid}" "${stunnel_pid}"; do
        if [ -n "${child_pid}" ]; then
            kill -TERM "${child_pid}" 2>/dev/null || :
        fi
    done

    for child_pid in "${haproxy_pid}" "${stunnel_pid}"; do
        if [ -n "${child_pid}" ]; then
            wait "${child_pid}" 2>/dev/null || :
        fi
    done
}

trap 'stop_children; exit 0' TERM INT

/docker-entrypoint.sh &
haproxy_pid="${!}"
stunnel '/homelab/stunnel.conf' &
stunnel_pid="${!}"

wait "${haproxy_pid}" "${stunnel_pid}"
