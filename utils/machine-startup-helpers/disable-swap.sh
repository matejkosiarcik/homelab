#!/bin/sh
set -euf
# This script disables swap on Raspberry Pi devices - should prolong SD card lifespan

sudo swapoff --all
