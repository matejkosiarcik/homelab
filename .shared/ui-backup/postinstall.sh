#!/bin/sh
set -euf

if [ "${PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD-0}" = 1 ]; then
    exit 0
fi

npx playwright install chromium
