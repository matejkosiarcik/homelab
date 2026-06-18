# syntax=docker/dockerfile:1

### App ###

FROM debian:13.5-slim AS libretranslate-build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=libretranslate-build-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=libretranslate-build-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        build-essential cmake g++ gcc libprotobuf-dev libsentencepiece-dev libsentencepiece0 pkg-config procps protobuf-compiler python3 python3-dev python3-pip python3-sentencepiece sentencepiece >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./external/libretranslate/requirements.txt ./
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,id=libretranslate-build-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
RUN --mount=type=cache,target=/root/.local,sharing=locked,id=libretranslate-build-language-models \
    (libretranslate --debug --update-models 2>&1 | tee ./status.txt &) && \
    sleep 1 && \
    while pgrep libretranslate >/dev/null 2>&1 && ! grep 'Running on ' <./status.txt >/dev/null; do true && \
        sleep 5 && \
    true; done && \
    if ! pgrep libretranslate >/dev/null 2>&1; then true && \
        printf 'Error during libretranslate update, process not running\n' >&2 && \
        exit 1 && \
    true; fi && \
    pkill -f libretranslate && \
    rm -f ./status.txt && \
    cp -R /root/.local /root/.local-copy

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=libretranslate-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=libretranslate-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.5-slim AS package-libsentencepiece
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=libretranslate-package-libsentencepiece-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=libretranslate-package-libsentencepiece-aptlibcache \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        libsentencepiece0 >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /homelab/usr-lib && \
    find /usr/lib -name 'libsentencepiece*' -exec sh -c 'mkdir -p "/homelab/usr-lib/$(dirname "$0" | sed -E "s~^/usr/lib/~~")" && cp "$0" "/homelab/usr-lib/$(dirname "$0" | sed -E "s~^/usr/lib/~~")/$(basename "$0")"' {} \;

FROM debian:13.5-slim AS empty-dir
USER root
RUN mkdir /empty

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/
COPY --from=libretranslate-build /homelab/python-vendor/ /homelab/python-vendor/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=libretranslate-build /root/.local-copy /home/homelab/.local
COPY --from=package-libsentencepiece /homelab/usr-lib/ /fsroot/usr-lib/

### Final ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/python3-debian13:latest
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/usr-lib/ /usr/lib/
WORKDIR /homelab
USER homelab
ENV HOMELAB_CONTAINER_NAME=libretranslate \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:5000" ]
ENTRYPOINT [ "libretranslate", "--host", "0.0.0.0", "--port", "5000", "--ssl", "--debug", "--metrics" ]
