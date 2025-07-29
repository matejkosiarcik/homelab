#!/bin/sh
set -euf

i=1
tail -n +2 <"$HOME/Downloads/majestic_million.csv" | while read -r entry; do
    domain="$(printf '%s' "$entry" | cut -d, -f3)"
    if printf '%s' "$domain" | grep -E -e '\.cn$' -e 'wixsite\.com$' -e 'cloudfront\.net$' -e 'blogspot\.com$' -e 'gouv\.fr$' >/dev/null 2>&1; then
        continue
    fi

    ip="$(dig '@10.1.20.1' '+short' "$domain" || (
        printf 'Not resolved %s %s\n' "$i" "$domain" >&2 && exit 1
    ))"
    # ip="$(dig '@127.0.0.1' -p '8053' '+short' "$domain" || (
    #     printf 'Not resolved %s %s\n' "$i" "$domain" >&2 && exit 1
    # ))"
    if [ "$ip" = "" ]; then
        printf '%s BAD (empty) - %s\n' "$i" "$domain"
    elif [ "$ip" = "0.0.0.0" ]; then
        printf '%s BAD (0.0.0.0) - %s\n' "$i" "$domain"
    else
        printf '%s GOOD - %s\n' "$i" "$domain"
    fi
    i="$((i + 1))"
done
