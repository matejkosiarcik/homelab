# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM python:3.12.6-slim AS supercronic-gitman
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.dependencies/gitman/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.dependencies/supercronic/gitman.yml ./
RUN gitman install --quiet

FROM golang:1.23.1-bookworm AS supercronic-build
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

FROM debian:12.7-slim AS prefinal
WORKDIR /homelab
COPY ./custom/postgres-backup/src/ ./src/
COPY ./.shared/cron-utils/cron-wrapper.sh ./.shared/cron-utils/entrypoint.sh ./custom/postgres-backup/crontab.cron ./custom/postgres-backup/main.sh ./
COPY --from=supercronic-build /homelab/supercronic/supercronic ./bin/

# TODO: Switch to regular stable debian when trixie is released
# Currently postgresql-client-16 is not available in bookworm
FROM debian:trixie-slim
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        postgresql-client-16 >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /backup /log
COPY --from=prefinal /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=postgres-backup \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="$PATH:/homelab/bin" \
    PGDATABASE=database \
    PGUSER=postgres \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=30s --timeout=1s CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.internal/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
