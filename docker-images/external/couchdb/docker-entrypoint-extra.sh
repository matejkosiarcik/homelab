# Copy everything from fake to real "local.d"
mkdir -p /opt/couchdb/etc/local.d
find /homelab/local.d -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/homelab/local.d/$(basename "$1")" "/opt/couchdb/etc/local.d/$(basename "$1")"' - {} \;

# Swap placeholders in "jwt.ini" with real values
HMAC_KEY_BASE64="$(printf "%s" "$HMAC_KEY" | base64)"
cat /opt/couchdb/etc/local.d/jwt.ini | sed "s~#hmac-key#~$HMAC_KEY_BASE64~g;s~#uuid#~$UUID~g" >/opt/couchdb/etc/local.d/jwt.ini2
mv /opt/couchdb/etc/local.d/jwt.ini2 /opt/couchdb/etc/local.d/jwt.ini
