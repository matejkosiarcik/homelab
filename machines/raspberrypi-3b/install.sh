#!/bin/sh
# shellcheck disable=SC2068

set -euf

# Prepare destination directory

bash "$(git rev-parse --show-toplevel)/.utils/preinstall-all.sh" $@

# Install individual services
# Note: Services ordered by priority and dependence on each other

install_script_path="$(git rev-parse --show-toplevel)/.utils/install-service.sh"

SOURCE_DIR="$(dirname "$0")/pi-hole" \
    bash "$install_script_path" $@

# SOURCE_DIR="$(dirname "$0")/debug" \
#     bash "$install_script_path" $@
