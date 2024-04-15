#!/bin/sh
set -euf

install_script_path="$(git rev-parse --show-toplevel)/.utils/install.sh"

SOURCE_DIR="$(dirname "$0")/pi-hole" \
    bash "$install_script_path"
