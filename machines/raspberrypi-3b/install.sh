#!/bin/sh
# shellcheck disable=SC2068

set -euf
cd "$(dirname "$0")"

install_script_path="$(git rev-parse --show-toplevel)/.utils/install.sh"

SOURCE_DIR="$(dirname "$0")/pi-hole" \
    bash "$install_script_path" $@

# SOURCE_DIR="$(dirname "$0")/debug" \
#     bash "$install_script_path" $@
