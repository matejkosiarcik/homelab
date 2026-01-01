#!/bin/sh
set -euf

cat "/homelab/config/$SAMBA_CONFIG.conf" |
    sed "s~#smb-title#~$SAMBA_TITLE~g" |
    sed "s~#smb-user#~$SAMBA_USERNAME~g" |
    sed "s~#smb-group#~$SAMBA_GROUP~g" \
    >/homelab/tmpfs/smb.conf

if ! grep -Eq "^$SAMBA_GROUP:" /etc/group; then
    printf 'Group %s not available\n' "$SAMBA_GROUP" >&2
    exit 1
fi
if ! grep -Eq "^$SAMBA_USERNAME:" /etc/passwd; then
    printf 'User %s not available\n' "$SAMBA_GROUP" >&2
    exit 1
fi
printf '%s\n%s\n' "$SAMBA_PASSWORD" "$SAMBA_PASSWORD" | smbpasswd -s -a "$SAMBA_USERNAME"

testparm -s /homelab/tmpfs/smb.conf || {
    printf '"testparm -s" failed with status %s\n' "$?" >&2
    exit 1
}

sleep 1

nohup /homelab/bin/samba_statusd &
nohup /homelab/bin/samba_exporter &
smbd --foreground --no-process-group --configfile='/homelab/tmpfs/smb.conf'
