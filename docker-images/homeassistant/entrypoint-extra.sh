#!/bin/sh

# Symlink main config files (configuration.yaml)
find '/homelab/config' -type f -mindepth 1 -maxdepth 1 -exec sh -c 'ln -sf "/homelab/config/$(basename "${1}")" "/config/$(basename "${1}")"' - {} \;

# Symlink custom config files (dashboards,scripts,includes,etc)
rm -rf '/config/custom'
mkdir -p '/config/custom'
find '/homelab/config/custom' -type f -mindepth 1 -maxdepth 1 -exec sh -c 'ln -sf "/homelab/config/custom/$(basename "${1}")" "/config/custom/$(basename "${1}")"' - {} \;
