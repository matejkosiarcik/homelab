# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest
# checkov:skip=CKV_DOCKER_8: Must run as root initially, and the linuxserver.io image switches to nonroot after it starts

### Other ###

FROM linuxserver/unifi-network-application:10.6.106 AS entrypoint
USER root
COPY ./docker-images/unifi-network-application/entrypoint-extra.sh /homelab/
RUN head -n 1 /init >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /init >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

FROM linuxserver/unifi-network-application:10.6.106 AS runtime_dirs
USER root
WORKDIR /homelab
RUN mkdir -p /homelab/original/defaults && \
    cp -R /defaults/. /homelab/original/defaults

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_unifi_network_application_user_setup_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_unifi_network_application_user_setup_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~abc~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~abc~' | sponge --append /etc/passwd && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~unifi~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~unifi~' | sponge --append /etc/passwd

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=runtime_dirs /homelab/original /homelab/original

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/init

### Final ###

FROM linuxserver/unifi-network-application:10.6.106
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
RUN find '.' \( -name 'favicon*.png' -or -name 'favicon*.ico' \) -type f -regex ".+/webapps/ROOT/app-unifi/angular/.+/images/favicons/.+" -exec cp {} './webapps/ROOT/app-unifi/angular/' \; && \
    if [ ! -e './webapps/ROOT/app-unifi/angular/favicon.ico' ]; then \
        printf 'File "favicon.ico" not found\n' >&2 && \
        exit 1 && \
    true; fi && \
    ln -s /config/data /usr/lib/unifi/data && \
    ln -s /config/logs /usr/lib/unifi/logs && \
    ln -s /run/unifi /usr/lib/unifi/run && \
    rm -rf /defaults && \
    chown -R homelab:homelab /usr/lib/unifi
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/init /
ARG GID=1000
ARG UID=1000
ENV FILE__MONGO_PASS="/homelab/mongodb-password.txt" \
    HOMELAB_CONTAINER_NAME="unificontroller" \
    HOMELAB_CONTAINER_VARIANT="default" \
    MEM_LIMIT="2048" \
    MEM_STARTUP="2048" \
    MONGO_AUTHSOURCE="admin" \
    MONGO_HOST="mongodb" \
    MONGO_DBNAME="unifi" \
    MONGO_PORT="27017" \
    MONGO_TLS="" \
    MONGO_USER="unifi" \
    PGID="${GID}" \
    PUID="${UID}"
# checkov:skip=CKV_SECRET_6: false positive in timezone
ENV TZ="Europe/Bratislava"
HEALTHCHECK --interval=10s --start-period=360s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "https_port=\"$(grep 'unifi.https.port' </defaults/system.properties | sed -E 's~^.+=~~')\" && if [ \"$(curl --insecure https://localhost:${https_port}/status | jq .meta.up)\" = 'true' ]; then exit 0; else exit 1; fi" ]
