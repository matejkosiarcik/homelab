# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_8: Ignore root user

FROM python:3.13.3-slim AS supercronic-gitman
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/gitman/requirements.txt ./
ENV PIP_ROOT_USER_ACTION=ignore
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.shared/dependencies/supercronic/gitman.yml ./
RUN gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

FROM golang:1.24.3-bookworm AS supercronic-build
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=supercronic-gitman /homelab/gitman-repositories/supercronic/ ./supercronic/
ENV CGO_ENABLED=0
WORKDIR /homelab/supercronic
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all supercronic
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh ./
RUN sh validate-executable.sh ./supercronic/supercronic

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./certs ./logs
COPY --from=supercronic-build /homelab/supercronic/supercronic ./bin/
COPY ./.shared/cron-utils/cron-wrapper.sh ./.shared/cron-utils/entrypoint.sh ./external/renovatebot/crontab.cron ./external/renovatebot/main.sh ./

FROM renovate/renovate:40.26.2-full
# hadolint ignore=DL3002
USER root
COPY --from=prefinal /homelab/ /homelab/
COPY ./external/renovatebot/config.js /usr/src/app/config.js
ENV HOMELAB_CONTAINER_NAME=renovatebot \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="$PATH:/homelab/bin" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=10m --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.internal/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
