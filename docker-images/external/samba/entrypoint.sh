#!/bin/sh
set -euf

SAMBA_GROUP="$SAMBA_USERNAME-group"

SAMBA_CONFIG_READONLY=''
SAMBA_CONFIG_WRITEABLE=''
if [ "${SAMBA_READONLY-}" = 'true' ]; then
    SAMBA_CONFIG_READONLY='yes'
    SAMBA_CONFIG_WRITEABLE='no'
else
    SAMBA_CONFIG_READONLY='no'
    SAMBA_CONFIG_WRITEABLE='yes'
fi

sed "s~#smb-title#~$SAMBA_TITLE~;s~#smb-user#~$SAMBA_USERNAME~;s~#smb-group#~$SAMBA_GROUP~;s~#smb-readonly#~$SAMBA_CONFIG_READONLY~;s~#smb-writeable#~$SAMBA_CONFIG_WRITEABLE~" </etc/samba/smb.conf |
    sponge /etc/samba/smb.conf

groupadd "$SAMBA_GROUP"
useradd -M -s /sbin/nologin "$SAMBA_USERNAME"
usermod -a -G "$SAMBA_GROUP" "$SAMBA_USERNAME"
printf '%s\n%s\n' "$SAMBA_PASSWORD" "$SAMBA_PASSWORD" | smbpasswd -s -a "$SAMBA_USERNAME"

testparm -s

smbd --foreground --no-process-group
