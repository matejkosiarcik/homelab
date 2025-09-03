# shellcheck disable=SC2148

# Copy everything from fake to real "/etc/nginx/conf.d"
mkdir -p /etc/nginx/conf.d
find /homelab/etc-nginx-conf.d -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/homelab/etc-nginx-conf.d/$(basename "$1")" "/etc/nginx/conf.d/$(basename "$1")"' - {} \;
