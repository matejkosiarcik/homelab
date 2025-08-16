# shellcheck disable=SC2148

# Copy everything from fake to real "/app/.next/server/pages"
mkdir -p /app/.next/server/pages
find /homelab/app-pages -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/homelab/app-pages/$(basename "$1")" "/app/.next/server/pages/$(basename "$1")"' - {} \;

# Copy everything from fake to real "/app/config"
mkdir -p /app/config
find /homelab/app-config -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/homelab/app-config/$(basename "$1")" "/app/config/$(basename "$1")"' - {} \;
