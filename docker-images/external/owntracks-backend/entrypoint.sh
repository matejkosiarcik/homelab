#!/bin/sh
set -euf

mkdir -p /var/spool/owntracks/recorder/store/
# if ! [ -f ${OTR_STORAGEDIR-/store}/ghash/data.mdb ]; then
# fi
ot-recorder --initialize

printf '%s %s' matej-iphone password | ocat --load=keys
#  -d /store/ghash/

sleep 5
printf 'Starting server:\n' >&2

/usr/sbin/entrypoint.sh
