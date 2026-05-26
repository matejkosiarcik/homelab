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
COPY ./external/ntfy/setup.sh /homelab/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY ./external/ntfy/config/server.yml /etc/ntfy/server.yml

### Final ###

FROM binwiederhier/ntfy:v2.15.0
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /etc/ntfy/server.yml /etc/ntfy/server.yml
ENV HOMELAB_CONTAINER_NAME=ntfy \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "/bin/sh", "-c", "wget -q --tries=1 http://localhost/v1/health -O - | grep -Eo '\"healthy\"\\s*:\\s*true' || exit 1" ]
ENTRYPOINT [ "ntfy" ]
CMD [ "serve" ]
