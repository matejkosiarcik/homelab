### Users ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base
USER root

FROM debian:13.2-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### App ###

FROM actualbudget/actual-server:25.12.0 AS actualbudget
USER root

### Final ###

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY ./external/actualbudget/healthcheck.js /homelab/
COPY --from=actualbudget /app /homelab/app

FROM gcr.io/distroless/nodejs22-debian13
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV ERR_ERL_UNEXPECTED_X_FORWARDED_FOR=false \
    HOMELAB_CONTAINER_NAME=actualbudget \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
WORKDIR /homelab/app
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/nodejs/bin/node", "/homelab/healthcheck.js" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/app/app.js" ]
CMD []
