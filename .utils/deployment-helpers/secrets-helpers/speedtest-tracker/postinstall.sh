#!/bin/sh
set -euf

rm -f "$PWD/src/.utils"
ln -f -s "$(git rev-parse --show-toplevel)/docker-images/custom/web-automation/src/.utils" "$PWD/src/.utils"

if [ "${PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD-0}" != '1' ]; then
    npx playwright install chromium
fi
