#!/bin/sh
set -euf

apk update --no-cache >/dev/null 2>&1
apk add --no-cache bash expect >/dev/null 2>&1

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

cat "/root/.config/glances/glances.pwd" | sed 's~^Do you want to save the password? [Yes/No]: ~~'
