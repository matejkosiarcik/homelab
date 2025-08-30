#!/bin/sh
set -euf

rm -f /home/user/.ollama/history

ollama serve
