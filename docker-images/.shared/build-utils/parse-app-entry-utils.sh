#!/bin/sh
set -euf

# This is equal to dirname
get_app_directory_name() {
    basename "$app_dirpath" | sed -E 's~^\.~~'
}

get_app_type() {
    app_type="$(yq --raw-output '.app.type' "$app_dirpath/config/config.yml")"
    if [ "$app_type" = '' ] || [ "$app_type" = 'null' ] || [ "$app_type" = 'undefined' ]; then
        app_type="$(get_app_directory_name)"
    fi

    if [ ! -d "/homelab/docker-compose/$app_type" ]; then
        printf 'App-template directory not found\n' >&2
        exit 1
    fi

    printf '%s\n' "$app_type"
}

get_server_name() {
    server_path="$(dirname "$(dirname "$app_dirpath")")"

    server_name="$(yq --raw-output '.server.name' "$server_path/config/config.yml")"
    if [ "$server_name" = '' ] || [ "$server_name" = 'null' ] || [ "$server_name" = 'undefined' ]; then
        printf 'Could not get server name\n' >&2
        exit 1
    fi

    printf '%s\n' "$server_name"
}

get_app_full_name_pretty() {
    app_template_prettyname="$(yq --raw-output '.app.name' "/homelab/docker-compose/$(get_app_type)/config.yml")"
    if [ "$app_template_prettyname" = '' ] || [ "$app_template_prettyname" = 'null' ] || [ "$app_template_prettyname" = 'undefined' ]; then
        printf 'Could not get app name\n' >&2
        exit 1
    fi

    app_instance_prettyname="$(yq --raw-output '.app.variant' "$app_dirpath/config/config.yml")"
    if [ "$app_instance_prettyname" = '' ] || [ "$app_instance_prettyname" = 'null' ] || [ "$app_instance_prettyname" = 'undefined' ]; then
        if [ "$(get_app_type)" = "$(get_app_directory_name)"  ]; then
            app_instance_prettyname=''
        else
            app_instance_prettyname="$(get_app_directory_name | sed -E "s~^$(get_app_type)\-~~;s~\-~ ~g" | sed -E 's~\b.~\u&~g')"
        fi
    fi

    app_prettyname="$app_template_prettyname"
    if [ "$app_instance_prettyname" != '' ]; then
        app_prettyname="$app_prettyname - $app_instance_prettyname"
    fi

    printf '%s\n' "$app_prettyname" | sed -E "s~<<server>>~$(get_server_name)~g"
}

get_app_full_name_machine() {
    get_app_full_name_pretty | tr '[:upper:]' '[:lower:]' | sed -E 's~ +~-~g;s~_+~-~g;s~\-+~-~g'
}

get_app_full_name_env() {
    get_app_full_name_machine | sed -E 's~-~_~g' | tr '[:lower:]' '[:upper:]'
}

get_app_domain() {
    domain="$(yq --raw-output '.network.domain' "$app_dirpath/config/config.yml")"
    if [ "$domain" = '' ] || [ "$domain" = 'null' ] || [ "$domain" = 'undefined' ]; then
        domain="$(get_app_full_name_machine).matejhome.com"
    fi

    printf '%s\n' "$domain"
}

replace_placeholders() {
    # $1 - input file
    sed -E "s~<<app-name-pretty>>~$app_full_name_pretty~g;s~<<app-name-machine>>~$app_full_name_machine~g;s~<<app-env>>~$app_full_name_env~g;s~<<server>>~$server_name~g" <"$1"
}
