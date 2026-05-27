### App ###

FROM ghcr.io/seanmorley15/adventurelog-backend:v0.11.0 AS adventurelog-backend

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Users ###

FROM debian:13.2-slim AS user-setup
USER root
COPY --from=adventurelog-backend /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM ghcr.io/seanmorley15/adventurelog-backend:v0.11.0
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
RUN ln -sf /run/supervisord.pid /code/supervisord.pid && \
    ln -sf /run/supervisord.log /code/supervisord.log && \
    ln -sf /run/scheduler.log /code/scheduler.log && \
    chown -R homelab:homelab /code /var/log/nginx
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV DEBUG=False \
    DISABLE_REGISTRATION=True \
    DJANGO_ADMIN_USERNAME=admin \
    EMAIL_BACKEND=email \
    EMAIL_HOST=smtp4dev.matejhome.com \
    EMAIL_PORT=25 \
    EMAIL_USE_SSL=False \
    EMAIL_USE_TLS=False \
    HOMELAB_CONTAINER_NAME=adventurelog \
    HOMELAB_CONTAINER_VARIANT=default \
    PGDATABASE=adventurelog \
    PGHOST=database \
    PGUSER=postgres \
    TZ=Europe/Bratislava
USER homelab
# Startup period a bit longer for initial migration - downloads stuff from github and sets up locations database
HEALTHCHECK --interval=10s --start-period=180s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8000" ]
