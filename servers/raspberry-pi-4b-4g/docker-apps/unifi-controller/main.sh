#!/bin/sh
set -euf

cd "$(dirname "$0")"

if [ "$(uname -m)" = arm64 ] || [ "$(uname -m)" = aarch64 ]; then
    DOCKER_COMPOSE_MONGODB_BUILD_CONTEXT='https://github.com/themattman/mongodb-raspberrypi-docker.git#:7.0.14'
    DOCKER_COMPOSE_MONGODB_BUILD_DOCKERFILE=''
else
    DOCKER_COMPOSE_MONGODB_BUILD_CONTEXT='../../../../docker-images/'
    DOCKER_COMPOSE_MONGODB_BUILD_DOCKERFILE='./external/mongodb/Dockerfile'
fi
export DOCKER_COMPOSE_MONGODB_BUILD_CONTEXT
export DOCKER_COMPOSE_MONGODB_BUILD_DOCKERFILE

# shellcheck disable=SC2068
bash "$(git rev-parse --show-toplevel)/.utils/deployment-helpers/docker-app-main.sh" $@
