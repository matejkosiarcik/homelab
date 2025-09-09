FROM debian:13.1-slim AS prefinal
RUN mkdir -p /homelab /homelab/logs

FROM vikunja/vikunja:0.24.6 AS vikunja

FROM debian:13.1-slim
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
COPY --chown=user:user ./external/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=prefinal --chown=user:user /homelab /homelab
COPY --from=vikunja --chown=user:user /app /app
ENV HOMELAB_CONTAINER_NAME=vikunja \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER user
WORKDIR /app/vikunja
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "./vikunja", "user", "list" ]
ENTRYPOINT ["/app/vikunja/vikunja"]
