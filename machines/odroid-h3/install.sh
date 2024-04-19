#!/bin/sh
set -euf
cd "$(dirname "$0")"

install_script_path="$(git rev-parse --show-toplevel)/.utils/install.sh"

SOURCE_DIR="$(dirname "$0")/smtp4dev" \
    bash "$install_script_path"

SOURCE_DIR="$(dirname "$0")/healthchecks" \
    bash "$install_script_path"

SOURCE_DIR="$(dirname "$0")/unifi-network-application" \
    bash "$install_script_path"
