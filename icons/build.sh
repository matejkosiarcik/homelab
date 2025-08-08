#!/bin/sh
set -euf

# shellcheck disable=SC2068
sh "$(dirname "$0")/build-diagrams.sh" $@

# shellcheck disable=SC2068
sh "$(dirname "$0")/build-favicons.sh" $@

# shellcheck disable=SC2068
sh "$(dirname "$0")/build-healthchecks.sh" $@

# shellcheck disable=SC2068
sh "$(dirname "$0")/build-homepage.sh" $@

# shellcheck disable=SC2068
sh "$(dirname "$0")/build-smtp4dev.sh" $@
