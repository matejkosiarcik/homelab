#!/bin/sh
set -euf

rm -f /home/homelab/.ollama/history

ollama serve
