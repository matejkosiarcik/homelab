# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS empty_dir
USER root
RUN mkdir /empty

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
USER root
WORKDIR /homelab
COPY --from=empty_dir /empty /homelab/healthchecks
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY ./docker-images/healthchecks/app/icons/healthchecks.png /custom-healthchecks.png

### Final ###

FROM healthchecks/healthchecks:v5.0@sha256:ba6276c008de510930749f61646ba21f52413c211248297eb4896e4b0d1a8d2e AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /custom-healthchecks.png /opt/healthchecks/static-collected/img/
ENV DB="sqlite" \
    DB_NAME="/homelab/healthchecks/database.db" \
    DEBUG="False" \
    EMAIL_HOST="smtp4dev.matejhome.com" \
    EMAIL_PORT="25" \
    EMAIL_USE_SSL="False" \
    EMAIL_USE_TLS="False" \
    HOMELAB_CONTAINER_NAME="healthchecks" \
    HOMELAB_CONTAINER_VARIANT="default" \
    INTEGRATIONS_ALLOW_PRIVATE_IPS="True" \
    PATH="/homelab/bin:${PATH}" \
    PROMETHEUS_ENABLED="True" \
    REGISTRATION_OPEN="False" \
    SECRET_KEY="" \
    SHELL_ENABLED="False" \
    SITE_LOGO_URL="/static/img/custom-healthchecks.png" \
    SITE_NAME="Healthchecks" \
    TZ="Europe/Bratislava"
# TODO: Enable secure emails
# EMAIL_HOST_PASSWORD=
# EMAIL_HOST_USER=
# EMAIL_USE_SSL=False
# EMAIL_USE_TLS=True
USER homelab
# Multiple statuses are for dev and prod environments
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "healthcheck", "--url", "http://localhost:8000", "--status", "200,400" ]
