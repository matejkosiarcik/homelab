# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### App ###

FROM vikunja/vikunja:2.8.0@sha256:35d937baf3b5d5803bed6b9e11d007448b7b536df9e4346dc35551e1072636c3 AS vikunja_app
USER root

### Other ###

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS package_ca_certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_package_ca_certificates_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_package_ca_certificates_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS empty_dir
USER root
RUN mkdir /empty

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=empty_dir /empty /homelab/logs

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY ./docker-images/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=vikunja_app /app /app
COPY --from=package_ca_certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/

### Final ###

FROM scratch AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /etc/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=prefinal --chown=homelab:homelab /app /app
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs /etc/ssl/certs
ENV HOMELAB_CONTAINER_NAME="vikunja" \
    HOMELAB_CONTAINER_VARIANT="default" \
    HOMELAB_TEST_PASSWORD="" \
    MATEJ_PASSWORD="" \
    PATH="/homelab/bin:${PATH}" \
    TZ="Europe/Bratislava" \
    VIKUNJA_METRICS_PASSWORD="" \
    VIKUNJA_SERVICE_SECRET=""
WORKDIR /app/vikunja
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=5s --retries=1 CMD [ "./vikunja", "user", "list" ]
ENTRYPOINT [ "/app/vikunja/vikunja" ]
