# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### App ###

FROM amir20/dozzle:v11.5.0@sha256:74600d62dd73a72a5d36fbd0c98af649203df921d74310b7ed383ef63392358e AS dozzle_app
USER root

### Users ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
USER root
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Other ###

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS package_ca_certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_package_ca_certificates_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_package_ca_certificates_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=dozzle_app /dozzle /dozzle
COPY --from=dozzle_app /data /data
COPY --from=package_ca_certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/

### Final ###

FROM scratch AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /dozzle /dozzle
COPY --from=prefinal --chown=homelab:homelab /data /data
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs /etc/ssl/certs
ENV DOZZLE_AUTH_PROVIDER="simple" \
    DOZZLE_CERT="/certs/dozzle-cert.pem" \
    DOZZLE_ENABLE_ACTIONS="false" \
    DOZZLE_HOSTNAME="Server" \
    DOZZLE_KEY="/certs/dozzle-key.pem" \
    DOZZLE_REMOTE_AGENT="dozzleagent-odroid-h3.matejhome.com:7007,dozzleagent-odroid-h4-ultra.matejhome.com:7007,dozzleagent-raspberry-pi-4b-2g.matejhome.com:7007,dozzleagent-raspberry-pi-4b-4g.matejhome.com:7007" \
    HOMELAB_CONTAINER_NAME="dozzle" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/dozzle", "healthcheck" ]
ENTRYPOINT [ "/dozzle" ]
