FROM ghcr.io/seanmorley15/adventurelog-frontend:v0.11.0 AS user-setup-base
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
COPY  ./external/actualbudget/healthcheck.js /homelab/

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
