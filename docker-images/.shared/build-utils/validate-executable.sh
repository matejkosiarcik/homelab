#!/bin/sh
# shellcheck disable=SC2251
# Inspect executables for unecessary baggage
set -euf

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments. Executable path not provided.\n' >&2
    exit 1
fi

# file "$1" | grep -i 'statically linked'

# Executables should be stripped of debug symbols
file "$1" | grep -i 'stripped'
! file "$1" | grep -i 'not stripped'
! file "$1" | grep -i 'with debuginfo'

# Executables should be built without BuildID - relevant for Rust and Go programs
! file "$1" | grep -i 'buildid'
! file "$1" | grep -i 'build-id'
