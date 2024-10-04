#!/bin/sh
set -euf

# The following just launches the app and filter unecessary debug/access logs
python ./changedetection.py -d /datastore 2>&1 | \
    grep --line-buffered -E -v "^\\([0-9]+\\) accepted \\('[0-9\\.]+', [0-9]+\\)\$" | \
    grep --line-buffered -E -v "^[0-9,\\.]+[ \\-]+\\[.+\\] \"(DELETE|GET|HEAD|POST|PUT) .+\" [0-9 \\.]+\$"
