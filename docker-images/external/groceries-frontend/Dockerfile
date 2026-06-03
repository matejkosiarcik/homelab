# syntax=docker/dockerfile:1

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=private,id=groceries-frontend-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=private,id=groceries-frontend-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM ghcr.io/davideshay/groceries-client:1.1.9 AS entrypoint
USER root
COPY ./external/groceries-frontend/entrypoint-extra.sh /homelab/
RUN head -n 1 /docker-entrypoint.sh >/homelab/entrypoint-shebang.sh && \
    tail -n +2 /docker-entrypoint.sh >/homelab/entrypoint-without-shebang.sh && \
    cat /homelab/entrypoint-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-without-shebang.sh >/docker-entrypoint.sh

FROM ghcr.io/davideshay/groceries-client:1.1.9 AS runtime-dirs
USER root
RUN mkdir -p /homelab/original/usr/share/nginx/html && \
    cp -R /usr/share/nginx/html/. /homelab/original/usr/share/nginx/html

### User setup ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
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
COPY --from=runtime-dirs /homelab/original /homelab/original
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY ./external/groceries-frontend/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=entrypoint /docker-entrypoint.sh /docker-entrypoint.sh

### Final ###

FROM ghcr.io/davideshay/groceries-client:1.1.9
USER root
RUN rm -rf /usr/share/nginx/html
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /docker-entrypoint.sh /docker-entrypoint.sh
# WORKDIR /homelab
ENV COUCHDB_USER=admin \
    DEFAULT_API_URL=https://placeholder.matejhome.com/api \
    HOMELAB_CONTAINER_NAME=groceries-frontend \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8100" ]
