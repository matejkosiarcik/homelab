# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### Build config ###

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_gitconfig_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_gitconfig_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    printf '' >/root/.gitconfig
# TODO: Re-enable cache below:
# COPY ./docker-images/.shared/anticache.txt /homelab/
# RUN printf '' >/root/.gitconfig && \
#     { curl --fail --silent 'https://gitcache-github.matejhome.com' || exit 0; } && \
#     git config --global 'url.https://gitcache-github.matejhome.com/.insteadOf' 'https://github.com/'

### Dependencies ###

FROM python:3.15.2-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5 AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS package_moreutils
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_script_setup_package_moreutils_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_script_setup_package_moreutils_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS package_ca_certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_package_ca_certificates_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_package_ca_certificates_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

FROM python:3.15.2-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5 AS package_curl_version
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_script_setup_package_curl_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_script_setup_package_curl_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git retry >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV GITMAN_CACHE="/root/.gitcache" \
    PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"
COPY ./docker-images/.shared/dependencies/static-curl/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet
WORKDIR /homelab/gitman-repositories/static-curl
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    git describe --tags --abbrev=0 --first-parent HEAD >'/homelab/curl-tag.txt'

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS package_curl_final
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_script_setup_package_curl_final_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_script_setup_package_curl_final_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl xz-utils >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=package_curl_version /homelab/curl-tag.txt /homelab/
RUN tag="$(cat '/homelab/curl-tag.txt')" && \
    asset="curl-linux-$(uname -m)-glibc-${tag}.tar.xz" && \
    tmpdir="$(mktemp -d)" && \
    curl --fail --silent --show-error --location --retry 3 --retry-connrefused --retry-max-time 60 \
        --output "${tmpdir}/release.html" \
        "https://github.com/stunnel/static-curl/releases/expanded_assets/${tag}" && \
    expected_sha256="$(grep --fixed-strings "aria-label=\"Copy to clipboard digest for ${asset}\"" "${tmpdir}/release.html" | sed -nE 's/.*value="sha256:([0-9a-f]{64})".*/\1/p')" && \
    test "${#expected_sha256}" -eq 64 && \
    curl --fail --silent --show-error --location --retry 3 --retry-connrefused --retry-max-time 60 --output "${tmpdir}/curl.tar.xz" "https://github.com/stunnel/static-curl/releases/download/${tag}/${asset}" && \
    printf '%s  %s\n' "${expected_sha256}" "${tmpdir}/curl.tar.xz" >"${tmpdir}/curl.tar.xz.sha256" && \
    sha256sum --check --status "${tmpdir}/curl.tar.xz.sha256" && \
    mkdir -p "${tmpdir}/curl.d" && \
    tar -xJf "${tmpdir}/curl.tar.xz" -C "${tmpdir}/curl.d" && \
    mkdir -p '/homelab/bin' && \
    cp "${tmpdir}/curl.d/curl" '/homelab/bin/' && \
    rm -rf "${tmpdir}"

FROM busybox:1.38.0-uclibc@sha256:b2e35951f72501f6a99f1bf45bcfe6d4795be08c518c2f97d0ed2fe776958a3b AS busybox
USER root
RUN mkdir -p '/fsroot/bin' && \
    cp -a '/bin/date' '/bin/grep' '/bin/sed' '/bin/sh' '/bin/sleep' '/bin/timeout' '/bin/wc' '/fsroot/bin/'

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

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

### Prefinal ###

FROM scratch AS homelab_dir
USER root
WORKDIR /homelab
COPY ./docker-images/script-setup/entrypoint.sh /homelab/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
ARG SETUP_SCRIPT_DIR="script-setup"
COPY ./docker-images/${SETUP_SCRIPT_DIR}/setup.sh /homelab/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=busybox /fsroot/bin/ /fsroot/bin/
COPY --from=package_ca_certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/
COPY --from=package_curl_final /homelab/bin/curl /fsroot/usr/bin/
COPY --from=package_moreutils /usr/bin/sponge /fsroot/usr/bin/

### Final ###

FROM gcr.io/distroless/base-debian13:latest@sha256:1eb7e763df3f75a0d0eab87368f04e1bc61ce268caf3f2cbae765fa8fd4fd3e8 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs /etc/ssl/certs
COPY --from=prefinal --chown=homelab:homelab /fsroot/bin/ /bin/
COPY --from=prefinal --chown=homelab:homelab /fsroot/usr/bin/ /usr/bin/
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME="script-setup" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    SPEEDTEST_RUN_TOKEN="" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=2m --timeout=5s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"file:///homelab/tmpfs/status.txt\",\"body\":\"started\\n\"}" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
