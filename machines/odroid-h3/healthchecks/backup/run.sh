#!/bin/sh
set -euf

pg_dump healthchecks \
    --data-only \
    --insert \
    --exclude-table-data=public.logs_record \
    --file=/backup/dump.sql
