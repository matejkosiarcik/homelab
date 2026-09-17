#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# This file replaces default "/etc/s6-overlay/s6-rc.d/svc-cron/run" to run supercronic instead of builtin cron daemon because of user permission conflicts

exec \
    s6-setuidgid abc \
    env HOME=/home/homelab USER=abc LOGNAME=abc SHELL=/bin/sh \
    /homelab/bin/supercronic \
    -split-logs \
    /homelab/crontabs/abc

sleep infinity
