# shellcheck disable=SC2148

# Copy files to real "/usr/share/nginx/html"
mkdir -p /usr/share/nginx/html
cp -R /homelab/original/usr/share/nginx/html/. /usr/share/nginx/html
