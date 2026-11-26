# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM openspeedtest/latest:v2.0.9@sha256:ba63bc8396e5ea334b58b96d925cd173957649935abb88efc9d8ada112cc45f8 AS entrypoint
USER root
COPY ./docker-images/openspeedtest/entrypoint-extra.sh /homelab/
RUN head -n 1 /entrypoint.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /entrypoint.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod 0500 /homelab/entrypoint-final.sh

FROM openspeedtest/latest:v2.0.9@sha256:ba63bc8396e5ea334b58b96d925cd173957649935abb88efc9d8ada112cc45f8 AS runtime_dirs
USER root
RUN mkdir -p '/homelab/original/etc/nginx/conf.d' && \
    cp -R '/etc/nginx/conf.d/.' '/homelab/original/etc/nginx/conf.d'

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_openspeedtest_user_setup_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_openspeedtest_user_setup_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~nginx~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~nginx~' | sponge --append /etc/passwd && \
    pwconv && \
    passwd --lock homelab && \
    passwd --lock nginx

### Prefinal ###

FROM scratch AS homelab_dir
USER root
WORKDIR /homelab
COPY --from=runtime_dirs /homelab/original /homelab/original
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/entrypoint.sh

### Final ###

FROM openspeedtest/latest:v2.0.9@sha256:ba63bc8396e5ea334b58b96d925cd173957649935abb88efc9d8ada112cc45f8 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
RUN chown -R homelab:homelab '/etc/nginx' && \
    ln -sf "$(which true)" "$(which crond)"
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/entrypoint.sh /
ARG GID=1000
ARG UID=1000
ENV ENABLE_LETSENCRYPT="False" \
    HOMELAB_CONTAINER_NAME="openspeedtest" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    PGID="${GID}" \
    PUID="${UID}" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=5s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"http://localhost:3000\"}" ]
