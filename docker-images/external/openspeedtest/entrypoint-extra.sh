# shellcheck disable=SC2148

# Copy everything from fake to real "/etc/nginx/conf.d"
mkdir -p /etc/nginx/conf.d
cp -R /homelab/original/etc/nginx/conf.d /etc/nginx/conf.d
