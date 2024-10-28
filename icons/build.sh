#!/bin/sh
set -euf

sh "$(dirname "$0")/build-diagrams.sh"
sh "$(dirname "$0")/build-healthchecks.sh"
sh "$(dirname "$0")/build-homepage.sh"
sh "$(dirname "$0")/build-homer.sh"
sh "$(dirname "$0")/build-http-proxy.sh"
sh "$(dirname "$0")/build-smtp4dev.sh"
