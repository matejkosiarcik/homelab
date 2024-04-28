#!/bin/sh
# shellcheck disable=SC2068

set -euf

install_script_path="$(git rev-parse --show-toplevel)/.utils/install-service.sh"

SOURCE_DIR="$(dirname "$0")/pi-hole" \
    bash "$install_script_path" $@

# SOURCE_DIR="$(dirname "$0")/debug" \
#     bash "$install_script_path" $@
