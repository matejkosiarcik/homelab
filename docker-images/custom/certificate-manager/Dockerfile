# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM python:3.12.5-slim AS supercronic-gitman
WORKDIR /app
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.dependencies/gitman/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/app/python-vendor/bin:$PATH" \
    PYTHONPATH=/app/python-vendor
COPY ./.dependencies/supercronic/gitman.yml ./
RUN gitman install --quiet

FROM golang:1.23.0-bookworm AS supercronic-build
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=supercronic-gitman /app/gitman-repositories/supercronic/ ./supercronic/
ENV CGO_ENABLED=0
WORKDIR /app/supercronic
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all supercronic
WORKDIR /app
COPY ./.shared/build-utils/validate-executable.sh ./
RUN sh validate-executable.sh ./supercronic/supercronic

FROM debian:12.7-slim AS prefinal
WORKDIR /app
RUN mkdir -p /certs /log
COPY --from=supercronic-build /app/supercronic/supercronic ./bin/
COPY ./.shared/cron-utils/cron-wrapper.sh ./.shared/cron-utils/entrypoint.sh ./custom/certificate-manager/crontab.cron ./custom/certificate-manager/main.sh ./

FROM debian:12.7-slim
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends openssl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /certs /log
COPY --from=prefinal /app /app
ENV HOMELAB_CONTAINER_NAME=certificate-manager \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="$PATH:/app/bin" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
