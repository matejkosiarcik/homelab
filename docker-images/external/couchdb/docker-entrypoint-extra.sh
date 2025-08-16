HMAC_KEY_BASE64="$(printf "%s" "$HMAC_KEY" | base64)"
cat /opt/couchdb/etc/local.d/jwt.ini | sed "s~#hmac-key#~$HMAC_KEY_BASE64~g" >/opt/couchdb/etc/local.d/jwt.ini2
mv /opt/couchdb/etc/local.d/jwt.ini2 /opt/couchdb/etc/local.d/jwt.ini
cat /opt/couchdb/etc/local.d/jwt.ini | sed "s~#uuid#~$UUID~g" >/opt/couchdb/etc/local.d/jwt.ini2
mv /opt/couchdb/etc/local.d/jwt.ini2 /opt/couchdb/etc/local.d/jwt.ini
