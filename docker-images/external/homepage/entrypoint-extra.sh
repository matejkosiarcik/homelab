# shellcheck disable=SC2148

# Copy files to real "/app/.next/server/pages"
mkdir -p /app/.next/server/pages
cp -R /homelab/original/app/.next/server/pages/. /app/.next/server/pages

# Copy files to real "/app/config"
mkdir -p /app/config
cp -R /homelab/config/. /app/config
