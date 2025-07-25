#!/bin/sh
set -euf
# This script just blocks all wireless modes (both bluetooth and wifi)

sudo rfkill block all
