# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY ./docker-images/smtp4dev/icons/favicon.ico ./docker-images/smtp4dev/icons/favicon.png /app/wwwroot/

### Final ###

FROM rnwood/smtp4dev:3.16.1@sha256:211a60c1a4f51ff7ace4a35de055797348994b0e84ab36734991235f90f9ac75 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /app/wwwroot/favicon.ico /app/wwwroot/favicon.png /app/wwwroot/
ENV HOMELAB_CONTAINER_NAME="smtp4dev" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    ServerOptions__LockSettings="true" \
    ServerOptions__Users__0__DefaultMailbox="Default" \
    ServerOptions__Users__0__Password="" \
    ServerOptions__Users__0__Username="matej" \
    ServerOptions__Users__1__DefaultMailbox="Default" \
    ServerOptions__Users__1__Password="" \
    ServerOptions__Users__1__Username="homelab-viewer" \
    ServerOptions__Users__2__DefaultMailbox="Default" \
    ServerOptions__Users__2__Password="" \
    ServerOptions__Users__2__Username="homelab-test" \
    ServerOptions__WebAuthenticationRequired="true" \
    TZ="Europe/Bratislava" \
    URLS="http://*:5000"

# TODO: Enable TLS below
# ServerOptions__TlsMode=StartTls
# ServerOptions__SecureConnectionRequired=true
# ServerOptions__TlsCertificate=/homelab/certs/server.pem
# ServerOptions__AuthenticationRequired=true

USER homelab

HEALTHCHECK --interval=10s --start-period=30s --timeout=5s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"http://localhost:5000\",\"basicAuthUsernameEnv\":\"ServerOptions__Users__1__Username\",\"basicAuthPasswordEnv\":\"ServerOptions__Users__1__Password\"}" ]
