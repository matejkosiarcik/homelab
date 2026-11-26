# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### Stunnel ###

FROM python:3.15.2-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5 AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'

FROM python:3.15.2-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5 AS stunnel_version
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_stunnel_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_stunnel_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git retry >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV GITMAN_CACHE="/root/.gitcache" \
    PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"
COPY ./docker-images/docker-socket-proxy/stunnel/gitman.yml /homelab/
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet
WORKDIR /homelab/gitman-repositories/stunnel
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    tag="$(git describe --tags --abbrev=0 --first-parent --match 'stunnel-[0-9]*' HEAD)" && \
    version="$(printf '%s\n' "${tag}" | sed -nE 's~^stunnel-([0-9]+\.[0-9]+)$~\1~p')" && \
    test -n "${version}" && \
    printf '%s\n' "${version}" >'/homelab/stunnel-version.txt'

FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf AS stunnel_build
USER root
WORKDIR /homelab
RUN apk add --no-cache build-base ca-certificates curl file linux-headers openssl-dev openssl-libs-static zlib-static
COPY --from=stunnel_version /homelab/stunnel-version.txt /homelab/
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN version="$(cat '/homelab/stunnel-version.txt')" && \
    archive="stunnel-${version}.tar.gz" && \
    curl --fail --silent --show-error --location --retry 3 --retry-connrefused --retry-max-time 60 --output "${archive}" "https://www.stunnel.org/downloads/${archive}" && \
    curl --fail --silent --show-error --location --retry 3 --retry-connrefused --retry-max-time 60 --output "${archive}.sha256" "https://www.stunnel.org/downloads/${archive}.sha256" && \
    sha256sum -c "${archive}.sha256" && \
    mkdir -p '/homelab/stunnel' && \
    tar -xzf "${archive}" --strip-components=1 -C '/homelab/stunnel'
WORKDIR /homelab/stunnel
RUN ./configure --prefix='/homelab' --with-ssl='/usr' --disable-shared --disable-systemd --disable-libwrap && \
    make -j"$(getconf _NPROCESSORS_ONLN)" && \
    mkdir -p '/homelab/bin' && \
    gcc -static -no-pie -Wl,--build-id=none,-z,noexecstack -o '/homelab/bin/stunnel' src/stunnel-*.o -lssl -lcrypto -lz && \
    strip --strip-all '/homelab/bin/stunnel' && \
    sh '/homelab/validate-executable.sh' '/homelab/bin/stunnel'

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

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### App ###

FROM linuxserver/socket-proxy:3.4.7@sha256:18289eeb306e8e3b70901ffec23eafbb318d73b4514d0bd737dbfc7c5b4fe506 AS app
USER root
RUN mkdir -p '/approot/bin' '/approot/lib' '/approot/usr/bin' '/approot/usr/lib' '/approot/usr/sbin' '/approot/usr/share/zoneinfo/Europe' && \
    cp -a '/bin/busybox' '/bin/cat' '/bin/mkdir' '/bin/sed' '/bin/sh' '/bin/sleep' '/approot/bin/' && \
    cp -a '/lib/ld-musl-'*'.so.'* '/lib/libc.musl-'*'.so.'* '/approot/lib/' && \
    cp -a '/templates' '/approot/' && \
    cp -a '/usr/sbin/haproxy' '/approot/usr/bin/' && \
    ln -s '../bin/haproxy' '/approot/usr/sbin/haproxy' && \
    cp -a '/usr/lib/libcrypto.so.'* '/usr/lib/libpcre2-8.so.'* '/usr/lib/libssl.so.'* '/usr/lib/libz.so.'* '/approot/usr/lib/' && \
    cp -L '/usr/lib/liblua-'*'.so.'* '/approot/usr/lib/' && \
    cp -L '/usr/share/zoneinfo/Europe/Bratislava' '/approot/usr/share/zoneinfo/Europe/'

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS app_entrypoint
USER root
WORKDIR /
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_jinja_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_jinja_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/docker-socket-proxy/docker-entrypoint.sh.patch /
COPY --from=app /docker-entrypoint.sh /
RUN git apply --check '/docker-entrypoint.sh.patch' && \
    git apply '/docker-entrypoint.sh.patch'

FROM scratch AS app_final
COPY --from=app /approot /approot
COPY --from=app_entrypoint /docker-entrypoint.sh /approot/

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=stunnel_build /homelab/bin/stunnel /homelab/bin/
COPY ./docker-images/docker-socket-proxy/stunnel/stunnel.conf /homelab/stunnel.conf
COPY ./docker-images/docker-socket-proxy/entrypoint.sh /homelab/entrypoint.sh

FROM scratch AS prefinal
COPY --from=app_final /approot /approot
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM scratch AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /approot/ /
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV ALLOW_ARCHIVE="0" \
    ALLOW_CHANGES="0" \
    ALLOW_EXPORT="0" \
    ALLOW_LOGS="0" \
    ALLOW_PAUSE="0" \
    ALLOW_RESTARTS="0" \
    ALLOW_START="0" \
    ALLOW_STOP="0" \
    ALLOW_TOP="0" \
    ALLOW_UNPAUSE="0" \
    AUTH="0" \
    BUILD="0" \
    COMMIT="0" \
    CONFIGS="0" \
    CONTAINERS="0" \
    DISABLE_IPV6="0" \
    DISTRIBUTION="0" \
    EVENTS="0" \
    EXEC="0" \
    HOMELAB_CONTAINER_NAME="docker-socket-proxy" \
    HOMELAB_CONTAINER_VARIANT="default" \
    IMAGES="0" \
    INFO="0" \
    LIBPOD_CONTAINERS="0" \
    LIBPOD_EVENTS="0" \
    LIBPOD_EXEC="0" \
    LIBPOD_GENERATE="0" \
    LIBPOD_IMAGES="0" \
    LIBPOD_INFO="0" \
    LIBPOD_MANIFESTS="0" \
    LIBPOD_NETWORKS="0" \
    LIBPOD_PING="0" \
    LIBPOD_PLAY="0" \
    LIBPOD_PODS="0" \
    LIBPOD_SECRETS="0" \
    LIBPOD_SYSTEM="0" \
    LIBPOD_VERSION="0" \
    LIBPOD_VOLUMES="0" \
    LOG_LEVEL="info" \
    NETWORKS="0" \
    NODES="0" \
    PING="0" \
    PLUGINS="0" \
    POST="0" \
    PATH="/homelab/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    SECRETS="0" \
    SERVICES="0" \
    SESSION="0" \
    SOCKET_PATH="/var/run/docker.sock" \
    SWARM="0" \
    SYSTEM="0" \
    TASKS="0" \
    TZ="Europe/Bratislava" \
    VERSION="0" \
    VOLUMES="0"
USER homelab
VOLUME /var/run/docker.sock
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"tcp://127.0.0.1:2376\"}", "--endpoint", "{\"url\":\"tcp://127.0.0.1:2375\"}" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
