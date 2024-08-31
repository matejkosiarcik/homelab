#!/bin/sh
set -euf

if [ "${PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD-0}" != '1' ]; then
    npx playwright install chromium
fi
