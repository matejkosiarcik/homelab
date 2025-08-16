# shellcheck disable=SC2148

# Copy everything from fake to real ".../nginx/html"
mkdir -p /usr/share/nginx/html
find /homelab/nginx-html -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/homelab/nginx-html/$(basename "$1")" "/usr/share/nginx/html/$(basename "$1")"' - {} \;
