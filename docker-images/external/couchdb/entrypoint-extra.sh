# shellcheck disable=SC2148

# Copy everything from fake to real "local.d"
mkdir -p /opt/couchdb/etc/local.d
cp -R /homelab/original/opt/couchdb/etc/local.d/. /opt/couchdb/etc/local.d

# Swap placeholders in "jwt.ini" with real values
HMAC_KEY_BASE64="$(printf "%s" "$HMAC_KEY" | base64)"
sed "s~#hmac-key#~$HMAC_KEY_BASE64~g;s~#uuid#~$UUID~g" </opt/couchdb/etc/local.d/jwt.ini >/opt/couchdb/etc/local.d/jwt.ini2
mv /opt/couchdb/etc/local.d/jwt.ini2 /opt/couchdb/etc/local.d/jwt.ini
