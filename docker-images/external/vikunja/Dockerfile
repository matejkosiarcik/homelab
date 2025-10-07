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
RUN if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        groupadd --gid "$GID" homelab && \
    true; else \
        oldgroupname="$(getent group "$GID" | cut -d: -f1)" && \
        groupmod --new-name homelab "$oldgroupname" && \
    true; fi && \
    nologinshell='' && \
    if [ -e /sbin/nologin ]; then \
        nologinshell='/sbin/nologin' && \
    true; elif [ -e /usr/sbin/nologin ]; then \
        nologinshell='/usr/sbin/nologin' && \
    true; else \
        nologinshell='/bin/false' && \
    true; fi && \
    if [ "$(getent passwd "$UID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        useradd --no-log-init --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" homelab && \
    true; else \
        oldusername="$(getent passwd "$UID" | cut -d: -f1)" && \
        usermod --move-home --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" --login homelab "$oldusername" && \
    true; fi && \
    mkdir -p /home/homelab /homelab && \
    chown -R homelab:homelab /home/homelab /homelab
COPY --chown=homelab:homelab ./external/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=vikunja --chown=homelab:homelab /app /app
ENV HOMELAB_CONTAINER_NAME=vikunja \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
WORKDIR /app/vikunja
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "./vikunja", "user", "list" ]
ENTRYPOINT ["/app/vikunja/vikunja"]
