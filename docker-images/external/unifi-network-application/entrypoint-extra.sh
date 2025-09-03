# shellcheck disable=SC2148

# Copy everything from fake to real "default"
mkdir -p /defaults
find /homelab/defaults -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/homelab/defaults/$(basename "$1")" "/defaults/$(basename "$1")"' - {} \;
