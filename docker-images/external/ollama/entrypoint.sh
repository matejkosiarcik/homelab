#!/bin/sh
set -euf

rm -f /root/.ollama/history

ollama serve
