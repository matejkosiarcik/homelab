# shellcheck disable=SC2148

# Copy everything from fake to real "local.d"
mkdir -p /usr/share/opensearch/config
cp -R /homelab/original/usr/share/opensearch/config/. /usr/share/opensearch/config
