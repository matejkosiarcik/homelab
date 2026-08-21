#!/bin/sh
set -euf

# This is equal to dirname
get_app_short_name_machine() {
    # Arg 1 - App directory path
    basename "$1" | sed -E 's~^\.~~'
}

get_app_type() {
    # Arg 1 - App directory path
    root_path="$(dirname "$(dirname "$(dirname "$(dirname "$1")")")")"

    app_type="$(yq --raw-output '.app.type' "$1/config/config.yml")"
    if [ "$app_type" = '' ] || [ "$app_type" = 'null' ] || [ "$app_type" = 'undefined' ]; then
        app_type="$(get_app_short_name_machine "$1")"
    fi

    if [ ! -d "$root_path/docker-compose/$app_type" ]; then
        printf 'App-template directory not found\n' >&2
        exit 1
    fi

    printf '%s\n' "$app_type"
}

get_server_name() {
    # Arg 1 - App directory path
    server_path="$(dirname "$(dirname "$1")")"

    server_name="$(yq --raw-output '.server.name' "$server_path/config/config.yml")"
    if [ "$server_name" = '' ] || [ "$server_name" = 'null' ] || [ "$server_name" = 'undefined' ]; then
        printf 'Could not get server name\n' >&2
        exit 1
    fi

    printf '%s\n' "$server_name"
}

get_app_full_name_pretty() {
    # Arg 1 - App directory path
    root_path="$(dirname "$(dirname "$(dirname "$(dirname "$1")")")")"

    app_template_prettyname="$(yq --raw-output '.app.name' "$root_path/docker-compose/$(get_app_type "$1")/config.yml")"
    if [ "$app_template_prettyname" = '' ] || [ "$app_template_prettyname" = 'null' ] || [ "$app_template_prettyname" = 'undefined' ]; then
        printf 'Could not get app name\n' >&2
        exit 1
    fi

    app_instance_prettyname="$(yq --raw-output '.app.variant' "$1/config/config.yml")"
    if [ "$app_instance_prettyname" = '' ] || [ "$app_instance_prettyname" = 'null' ] || [ "$app_instance_prettyname" = 'undefined' ]; then
        if [ "$(get_app_type "$1")" = "$(get_app_short_name_machine "$1")" ]; then
            app_instance_prettyname=''
        else
            app_instance_prettyname="$(get_app_short_name_machine "$1" | sed -E "s~^$(get_app_type "$1")\-~~;s~\-~ ~g")"
        fi
    fi

    app_prettyname="$app_template_prettyname"
    if [ "$app_instance_prettyname" != '' ]; then
        app_prettyname="$app_prettyname - $app_instance_prettyname"
    fi

    printf '%s\n' "$app_prettyname" | sed -E "s~<<server>>~$(get_server_name "$1")~g"
}

get_app_full_name_machine() {
    # Arg 1 - App directory path
    get_app_full_name_pretty "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's~(\[|\]|\(|\)|\{|\}|\_|\+|\ |\-)~-~g;s~\-+~-~g'
}

get_app_full_name_env() {
    # Arg 1 - App directory path
    get_app_full_name_machine "$1" | sed -E 's~-~_~g' | tr '[:lower:]' '[:upper:]'
}

get_app_domain() {
    # Arg 1 - App directory path
    domain="$(yq --raw-output '.network.domain' "$1/config/config.yml")"
    if [ "$domain" = '' ] || [ "$domain" = 'null' ] || [ "$domain" = 'undefined' ]; then
        domain="$(get_app_full_name_machine "$1").matejhome.com"
    fi

    printf '%s\n' "$domain"
}

get_app_ip() {
    # Arg 1 - App directory path
    ip="$(yq --raw-output '.network.ip' "$1/config/config.yml")"
    if [ "$ip" = '' ] || [ "$ip" = 'null' ] || [ "$ip" = 'undefined' ]; then
        ip='0.0.0.0'
    fi

    printf '%s\n' "$ip"
}
