#!/bin/sh

apk update --no-cache
apk add --no-cache bash expect

expect <<EOF
set timeout -1
spawn glances -s --password
expect -- "Define the Glances server password (glances username):"
send -- "$PASSWORD\n"
expect -- "Password (confirm):"
send -- "$PASSWORD\n"
expect -- "Do you want to save the password?"
send -- "yes\n"
interact
sleep 10
EOF
