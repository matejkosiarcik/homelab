### App ###

FROM ghcr.io/seanmorley15/adventurelog-frontend:v0.11.0 AS adventurelog-frontend

### Users ###

FROM debian:13.2-slim AS user-setup
USER root
COPY --from=adventurelog-frontend /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY  ./external/actualbudget/healthcheck.js ./

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM ghcr.io/seanmorley15/adventurelog-frontend:v0.11.0
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV BODY_SIZE_LIMIT=Infinity \
    HOMELAB_CONTAINER_NAME=adventurelog \
    HOMELAB_CONTAINER_VARIANT=default \
    PUBLIC_SERVER_URL=http://app-backend:8000 \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "wget -O /dev/null http://localhost:3000 || exit 1" ]
