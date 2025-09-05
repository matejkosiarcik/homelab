FROM python:3.13.7-slim AS minio-mc-gitman
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
COPY ./external/minio-client/gitman.yml ./
RUN gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

FROM golang:1.25.1-bookworm AS minio-mc-build
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=minio-mc-gitman /homelab/gitman-repositories/minio-mc/ ./minio-mc/
ENV CGO_ENABLED=0
WORKDIR /homelab/minio-mc
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all mc
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh ./
RUN sh validate-executable.sh ./minio-mc/mc

FROM debian:13.0-slim AS prefinal
WORKDIR /homelab
COPY --from=minio-mc-build /homelab/minio-mc/mc ./bin/
COPY ./external/minio-client/entrypoint.sh ./external/minio-client/main.sh ./external/minio-client/plain-buckets.txt ./external/minio-client/versioned-buckets.txt ./

FROM debian:13.0-slim
ARG UID=1000
ARG GID=1000
RUN mkdir -p /homelab && \
    ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    chown -R user:user /homelab
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal --chown=user:user /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=certificator \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.status/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
USER user
