#!/bin/sh
set -euf

printf 'Starting glances password\n'

apk update --no-cache
apk add --no-cache bash expect

expect -c "
set timeout -1
spawn glances -s --password
expect -- \"Define the Glances server password (glances username):\"
send -- \"$PASSWORD\n\"
expect -- \"Password (confirm):\"
send -- \"$PASSWORD\n\"
expect -- \"Do you want to save the password?\"
send -- \"yes\n\"
interact
sleep 10
"

printf 'Glances config directory:\n'
ls -lah /root/.config/glances
printf 'Glances end.\n'
