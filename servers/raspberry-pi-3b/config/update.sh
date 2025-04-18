#!/bin/sh
set -euf

cd "$(dirname "$(dirname "$0")")" >/dev/null 2>&1
git_dir="$(cd "$(dirname "$0")" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$HOME/git/homelab")"

sh "$git_dir/.utils/others/update.sh"
