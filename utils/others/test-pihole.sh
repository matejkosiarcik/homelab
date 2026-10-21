#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

i=1
tail -n +2 <"${HOME}/Downloads/majestic_million.csv" | while read -r entry; do
    domain="$(printf '%s' "${entry}" | cut -d, -f3)"
    if printf '%s' "${domain}" | grep -E -e '\.cn$' -e 'wixsite\.com$' -e 'cloudfront\.net$' -e 'blogspot\.com$' -e 'gouv\.fr$' >'/dev/null' 2>&1; then
        continue
    fi

    ip="$(dig '@10.1.12.1' '+short' "${domain}" || (
        printf '%s [ERROR]: Not resolved %s %s\n' "$(date "${datetime_format}")" "${i}" "${domain}" >&2 && exit 1
    ))"
    # ip="$(dig '@127.0.0.1' -p '8053' '+short' "${domain}" || (
    #     printf 'Not resolved %s %s\n' "${i}" "${domain}" >&2 && exit 1
    # ))"
    if [ "${ip}" = "" ]; then
        printf '%s [WARNING]: %s BAD (empty) - %s\n' "$(date "${datetime_format}")" "${i}" "${domain}"
    elif [ "${ip}" = "0.0.0.0" ]; then
        printf '%s [WARNING]: %s BAD (0.0.0.0) - %s\n' "$(date "${datetime_format}")" "${i}" "${domain}"
    else
        printf '%s [INFO]: %s GOOD - %s\n' "$(date "${datetime_format}")" "${i}" "${domain}"
    fi
    i="$((i + 1))"
done
