# syntax=docker/dockerfile:1

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=smtp4dev-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=smtp4dev-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

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
COPY --from=healthcheck-build /homelab/healthcheck /homelab/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY ./external/smtp4dev/icons/favicon.ico ./external/smtp4dev/icons/favicon.png /app/wwwroot/

### Final ###

FROM rnwood/smtp4dev:3.12.0
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /app/wwwroot/favicon.ico /app/wwwroot/favicon.png /app/wwwroot/
ENV HOMELAB_CONTAINER_NAME=smtp4dev \
    HOMELAB_CONTAINER_VARIANT=default \
    ServerOptions__LockSettings=true \
    ServerOptions__Users__0__DefaultMailbox=Default \
    ServerOptions__Users__0__Username=matej \
    ServerOptions__Users__1__DefaultMailbox=Default \
    ServerOptions__Users__1__Username=homelab-viewer \
    ServerOptions__Users__2__DefaultMailbox=Default \
    ServerOptions__Users__2__Username=homelab-test \
    ServerOptions__WebAuthenticationRequired=true \
    TZ=Europe/Bratislava \
    URLS=http://*:5000

# TODO: Enable TLS below
# ServerOptions__TlsMode=StartTls
# ServerOptions__SecureConnectionRequired=true
# ServerOptions__TlsCertificate=/homelab/certs/server.pem
# ServerOptions__AuthenticationRequired=true

USER homelab

# Note: curl/wget isn't available, so we have to resort to bash
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:5000" ]
