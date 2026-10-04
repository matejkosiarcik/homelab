#!/bin/sh
set -euf

rm -f '/home/homelab/.ollama/history'

exec ollama serve
