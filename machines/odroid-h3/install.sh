#!/bin/sh
# shellcheck disable=SC2068

set -euf
cd "$(dirname "$0")"

install_script_path="$(git rev-parse --show-toplevel)/.utils/install-service.sh"

# Note: Services ordered by priority and dependence on each other

SOURCE_DIR="$(dirname "$0")/smtp4dev" \
    bash "$install_script_path" $@

SOURCE_DIR="$(dirname "$0")/homer" \
    bash "$install_script_path" $@

SOURCE_DIR="$(dirname "$0")/healthchecks" \
    bash "$install_script_path" $@

SOURCE_DIR="$(dirname "$0")/uptime-kuma" \
    bash "$install_script_path" $@

SOURCE_DIR="$(dirname "$0")/omada-controller" \
    bash "$install_script_path" $@

SOURCE_DIR="$(dirname "$0")/unifi-network-application" \
    bash "$install_script_path" $@
