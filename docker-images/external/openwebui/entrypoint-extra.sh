# shellcheck disable=SC2148

# Copy files to real "/app/backend/open_webui/static"
mkdir -p /app/backend/open_webui/static
cp -R /homelab/original/app/backend/open_webui/static/. /app/backend/open_webui/static
