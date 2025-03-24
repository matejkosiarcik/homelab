#!/bin/sh
set -euf

SAMBA_GROUP="$SAMBA_USERNAME-group"
samba_file="/homelab/smb/smb-$SAMBA_CONFIG.conf"

sed "s~#smb-title#~$SAMBA_TITLE~;s~#smb-user#~$SAMBA_USERNAME~;s~#smb-group#~$SAMBA_GROUP~" <"$samba_file" >/etc/samba/smb.conf

if ! grep -Eq "^$SAMBA_GROUP:" /etc/group; then
    groupadd "$SAMBA_GROUP"
fi
if ! grep -Eq "^$SAMBA_USERNAME:" /etc/passwd; then
    useradd -M -s /sbin/nologin "$SAMBA_USERNAME"
    usermod -a -G "$SAMBA_GROUP" "$SAMBA_USERNAME"
fi
printf '%s\n%s\n' "$SAMBA_PASSWORD" "$SAMBA_PASSWORD" | smbpasswd -s -a "$SAMBA_USERNAME"

testparm -s

smbd --foreground --no-process-group
