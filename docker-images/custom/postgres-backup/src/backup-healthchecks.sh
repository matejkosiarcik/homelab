#!/bin/sh
set -euf

current_date="$(date '+%Y-%m-%d_%H-%M-%S')"

pg_dump "$PGDATABASE" \
    --data-only \
    --insert \
    --exclude-table-data=public.logs_record \
    --file="/backup/$current_date-dump.sql"
