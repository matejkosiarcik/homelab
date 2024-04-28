#!/bin/sh
# shellcheck disable=SC2068

set -euf

# Prepare destination directory

bash "$(git rev-parse --show-toplevel)/.utils/preinstall-all.sh" $@

# Install individual services
# Note: Services ordered by priority and dependence on each other

currdir="$(cd "$(dirname "$0")" && printf '%s\n' "$PWD")"
install_script_path="$(git rev-parse --show-toplevel)/.utils/install-service.sh"

SOURCE_DIR="$currdir/smtp4dev" \
    bash "$install_script_path" $@

SOURCE_DIR="$currdir/homer" \
    bash "$install_script_path" $@

SOURCE_DIR="$currdir/healthchecks" \
    bash "$install_script_path" $@

SOURCE_DIR="$currdir/uptime-kuma" \
    bash "$install_script_path" $@

SOURCE_DIR="$currdir/omada-controller" \
    bash "$install_script_path" $@

SOURCE_DIR="$currdir/unifi-network-application" \
    bash "$install_script_path" $@
