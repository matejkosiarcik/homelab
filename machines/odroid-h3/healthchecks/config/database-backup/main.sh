#!/bin/sh
set -euf

pg_dump "$PGDATABASE" \
    --data-only \
    --insert \
    --exclude-table-data=public.logs_record \
    --file=/backup/dump.sql
