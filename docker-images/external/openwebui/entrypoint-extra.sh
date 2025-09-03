# shellcheck disable=SC2148

# Copy everything from fake to real "/app/backend/open_webui/static"
mkdir -p /app/backend/open_webui/static
find /homelab/app-static -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/homelab/app-static/$(basename "$1")" "/app/backend/open_webui/static/$(basename "$1")"' - {} \;
