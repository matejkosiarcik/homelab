# checkov:skip=CKV_DOCKER_8: Must run as root initially, but we switch to non-root user in entrypoint

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.2-slim AS empty-dir
USER root
RUN mkdir /empty && \
    touch /empty.txt

### Users ###

FROM debian:13.2-slim AS user-setup-base
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        apache2 && \
    rm -rf /var/lib/apt/lists/*

FROM debian:13.2-slim AS user-setup
USER root
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
USER root
WORKDIR /homelab
COPY --from=empty-dir /empty /homelab/certs
COPY --from=empty-dir /empty /homelab/logs
COPY --from=empty-dir /empty.txt /homelab/users/empty.htpasswd
COPY ./custom/apache/www ./www
COPY ./custom/apache/entrypoint.sh /homelab/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY ./custom/apache/apache.conf /apache.conf

### Final ###

FROM debian:13.2-slim
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        apache2 inotify-tools && \
    rm -rf /var/lib/apt/lists/* && \
    a2enmod auth_basic env headers http2 macro proxy proxy_http proxy_http2 proxy_wstunnel rewrite ssl status && \
    a2dismod -f alias && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/*
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /apache.conf /etc/apache2/sites-enabled/apache.conf
WORKDIR /homelab
# For debugging enable following modules: dump_io log_forensic
# NOTE: "alias" module is disabled because it causes 403/404 errors, see also: https://serverfault.com/questions/153177/apache2-and-icons-path-behaving-differently
ENV HOMELAB_CONTAINER_NAME=apache \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "https://localhost/.apache", "--insecure" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
