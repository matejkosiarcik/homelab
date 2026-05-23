FROM gcr.io/distroless/static-debian13 AS user-setup-base
USER root

FROM debian:13.2-slim AS user-setup
USER root
ARG GID=1000
ARG UID=1000
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

FROM scratch AS prefinal
WORKDIR /homelab
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY ./external/apache-prometheus-exporter/entrypoint.sh /homelab/

FROM debian:13.2-slim
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        prometheus-apache-exporter curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /homelab
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV HOMELAB_CONTAINER_NAME=apache-prometheus-exporter \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "curl --fail http://localhost:9117/metrics || exit 1" ]
