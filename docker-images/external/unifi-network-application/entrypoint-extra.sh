# shellcheck disable=SC2148

# Copy everything from fake to real "default"
mkdir -p /defaults
find /homelab/defaults -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/homelab/defaults/$(basename "$1")" "/defaults/$(basename "$1")"' - {} \;

# Install custom certificate
if [ ! -e '/config/data/custom-certificates' ]; then
    original_dir="$pwd"
    mkdir -p /config/data/custom-certificates
    cd /config/data/custom-certificates
    # mv ../keystore "./keystore.bak.$(date +"%Y-%m-%d_%H-%M-%S")"

    # Create certificate signing request
    keytool -genkeypair -alias unifi -keyalg RSA -keysize 2048 -dname "CN=$HOMELAB_APP_EXTERNAL_DOMAIN, OU=Homelab, O=Homelab, L=Bratislava, S=SK, C=SK" -ext "SAN=DNS:$HOMELAB_APP_EXTERNAL_DOMAIN,DNS:unifi,IP:$HOMELAB_APP_EXTERNAL_IP" -keystore keystore -storepass aircontrolenterprise
    keytool -certreq -alias unifi -ext "SAN=DNS:$HOMELAB_APP_EXTERNAL_DOMAIN,DNS:unifi,IP:$HOMELAB_APP_EXTERNAL_IP" -keystore keystore -storepass aircontrolenterprise -file unifi.req

    # Create certificate for custom CA
    openssl genrsa -out ca.key 4096
    openssl req -x509 -new -nodes -key ca.key -sha256 -days 3651 -subj "/C=SK/ST=SK/L=Bratislava/O=Homelab/OU=Homelab/CN=Homelab" -out ca.pem

    # Sign the CSR with our CA to create output certificate
    printf '%s\n' "subjectAltName = DNS:$HOMELAB_APP_EXTERNAL_DOMAIN, DNS:unifi, IP:$HOMELAB_APP_EXTERNAL_IP" >extfile.cnf
    openssl x509 -req -in unifi.req -CA ca.pem -CAkey ca.key -CAcreateserial -out unifi.crt -days 3650 -sha256 -extfile extfile.cnf

    # Import certificates
    keytool -import -noprompt -alias ca -file ca.pem -keystore keystore -storepass aircontrolenterprise
    keytool -import -noprompt -alias unifi -file unifi.crt -keystore keystore -storepass aircontrolenterprise

    cp ./keystore ../keystore
    cd "$original_dir"
fi
