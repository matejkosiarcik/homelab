#!/bin/sh
set -euf

# TODO: Read mode from global .env file
mode='prod'

# Pull latest git changes
if [ "$(git branch --show-current)" != 'main' ]; then
    printf "Git repository is on branch %s instead of main, can't update.\n" "$(git branch --show-current)"
    exit 1
fi
if [ "$(git status --short)" != '' ]; then
    printf "Git repository is dirty, can't update. Current changes: %s\n" "$(git status --short)"
    exit 1
fi
git pull --ff-only

# Run build
find docker-apps -type d -mindepth 1 -maxdepth 1 -not -name '.*' | while read -r dir; do
    sh main.sh build --only "$dir" "--$mode"
done

# Run deploy
find docker-apps -type d -mindepth 1 -maxdepth 1 | while read -r dir; do
    sh main.sh deploy --only "$dir" "--$mode"
done
