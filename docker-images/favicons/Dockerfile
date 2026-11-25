# syntax=docker/dockerfile:1

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

FROM node:26.13.1-slim@sha256:abe7e5a82b61a8ef67b315b85497c9e65173387ccf2f4a029248184b8e020be5 AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_npmconfig_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_npmconfig_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    touch '/root/.npmrc'
# TODO: Re-enable cache below:
# COPY ./docker-images/.shared/anticache.txt /homelab/
# RUN touch '/root/.npmrc' && \
#     { curl --fail --silent https://npmcache.matejhome.com || exit 0; } && \
#     npm config set proxy https://npmcache.matejhome.com && \
#     npm config set https-proxy https://npmcache.matejhome.com

### Dependencies ###

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_yq_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_yq_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'
ENV PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS jinja
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_jinja_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_jinja_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/jinja/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'
ENV PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"

FROM python:3.15.2-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5 AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'

FROM python:3.15.2-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5 AS imagemagick_appimage_version
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_favicons_imagemagick_appimage_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_favicons_imagemagick_appimage_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git retry >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV GITMAN_CACHE="/root/.gitcache" \
    PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"
COPY ./docker-images/.shared/dependencies/imagemagick-appimage/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet
WORKDIR /homelab/gitman-repositories/imagemagick-appimage
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    cat './LATEST_VERSION' >'/homelab/imagemagick-version.txt' && \
    git describe --tags --abbrev=0 --first-parent HEAD >'/homelab/imagemagick-tag.txt'

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS imagemagick_final
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_favicons_imagemagick_final_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_favicons_imagemagick_final_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=imagemagick_appimage_version /homelab/imagemagick-tag.txt /homelab/imagemagick-version.txt /homelab/
RUN tag="$(cat '/homelab/imagemagick-tag.txt')" && \
    version="$(cat '/homelab/imagemagick-version.txt')" && \
    asset="ImageMagick-${version}-anylinux-$(uname -m).AppImage" && \
    tmpdir="$(mktemp -d)" && \
    curl --fail --silent --show-error --location --retry 3 --retry-connrefused --retry-max-time 60 \
        --output "${tmpdir}/release.html" \
        "https://github.com/pkgforge-dev/ImageMagick-AppImage/releases/expanded_assets/${tag}" && \
    expected_sha256="$(grep --fixed-strings "aria-label=\"Copy to clipboard digest for ${asset}\"" "${tmpdir}/release.html" | sed -nE 's/.*value="sha256:([0-9a-f]{64})".*/\1/p')" && \
    test "${#expected_sha256}" -eq 64 && \
    curl --fail --silent --show-error --location --retry 3 --retry-connrefused --retry-max-time 60 --output "${tmpdir}/ImageMagick.AppImage" "https://github.com/pkgforge-dev/ImageMagick-AppImage/releases/download/${tag}/${asset}" && \
    printf '%s  %s\n' "${expected_sha256}" "${tmpdir}/ImageMagick.AppImage" >"${tmpdir}/ImageMagick.AppImage.sha256" && \
    sha256sum --check --status "${tmpdir}/ImageMagick.AppImage.sha256" && \
    chmod a+x "${tmpdir}/ImageMagick.AppImage" && \
    "${tmpdir}/ImageMagick.AppImage" --appimage-extract && \
    mv "./AppDir" '/homelab/imagemagick' && \
    rm -rf "${tmpdir}" && \
    find '/homelab/imagemagick' -mindepth 1 -maxdepth 1 -not -type d -exec rm -f {} \; && \
    find '/homelab/imagemagick' -mindepth 1 -maxdepth 1 -type d -not \( -name 'bin' -or -name 'lib' -or -name 'shared' \) -exec rm -rf {} \; && \
    find '/homelab/imagemagick/shared' -mindepth 1 -maxdepth 1 -not \( -name 'bin' -or -name 'lib' \) -exec rm -f {} \; && \
    find '/homelab/imagemagick/bin' -mindepth 1 -maxdepth 1 -not \( -name 'magick' -or -name 'convert' \) -exec rm -f {} \; && \
    find '/homelab/imagemagick/shared/bin' -mindepth 1 -maxdepth 1 -not \( -name 'magick' -or -name 'convert' \) -exec rm -f {} \; && \
    find '/homelab/imagemagick/lib' -mindepth 1 -maxdepth 1 -type d -not \( -name 'ImageMagick-*' -or -name 'sharun-preload' \) -exec rm -rf {} \; && \
    find '/homelab/imagemagick/lib' -path '*/ImageMagick-*/modules-*/coders/*' -not \( -name 'icon.*' -or -name 'png.*' -or -name 'webp.*' \) -exec rm -f {} \; && \
    find '/homelab/imagemagick/lib' -path '*/ImageMagick-*/modules-*/*' -name 'filters' -prune -exec rm -rf {} \; && \
    find '/homelab/imagemagick/lib' -mindepth 1 -maxdepth 1 \( -type f -or -type l \) \
        -not \( \
            -name 'ld-linux-*' -or \
            -name 'libanl.so*' -or \
            -name 'libbrotlicommon.so*' -or \
            -name 'libbrotlidec.so*' -or \
            -name 'libbz*.so*' -or \
            -name 'libc.so*' -or \
            -name 'libcrypt.so*' -or \
            -name 'libdl.so*' -or \
            -name 'libexpat.so*' -or \
            -name 'libfftw*.so*' -or \
            -name 'libfontconfig.so*' -or \
            -name 'libfreetype.so*' -or \
            -name 'libfribidi.so*' -or \
            -name 'libgcc_s.so*' -or \
            -name 'libglib-*.*.so*' -or \
            -name 'libgomp.so*' -or \
            -name 'libgraphite*.so*' -or \
            -name 'libharfbuzz.so*' -or \
            -name 'liblcms*.so*' -or \
            -name 'liblqr-*.so*' -or \
            -name 'libltdl.so*' -or \
            -name 'libm.so*' -or \
            -name 'libMagickCore-*.*.so*' -or \
            -name 'libMagickWand-*.*.so*' -or \
            -name 'libpcre*-*.so*' -or \
            -name 'libpng*.so*' -or \
            -name 'libpthread.so*' -or \
            -name 'libraqm.so*' -or \
            -name 'libresolv.so*' -or \
            -name 'librt.so*' -or \
            -name 'libsharpyuv.so*' -or \
            -name 'libutil.so*' -or \
            -name 'libwebp.so*' -or \
            -name 'libwebpdemux.so*' -or \
            -name 'libwebpmux.so*' -or \
            -name 'libX11.so*' -or \
            -name 'libXau.so*' -or \
            -name 'libxcb.so*' -or \
            -name 'libXdmcp.so*' -or \
            -name 'libXext.so*' -or \
            -name 'libxml*.so*' -or \
            -name 'libz.so*' \
        \) -exec rm -rf {} \; && \
    coders_dir="$(find '/homelab/imagemagick/lib' -type d -path '*/ImageMagick-*/modules-*/coders' -print -quit | sed -E 's~^/homelab/imagemagick/lib~~')" && \
    printf '%s\n' '+' '+/sharun-preload' "+${coders_dir}" >'/homelab/imagemagick/lib/lib.path'
COPY ./docker-images/favicons/test-icons/test.png ./docker-images/favicons/test-icons/test.ico /homelab/test-icons/
ENV PATH="/homelab/imagemagick/bin:${PATH}"
RUN tmpdir="$(mktemp -d)" && \
    mkdir -p "${tmpdir}/ico2png" "${tmpdir}/png2png" && \
    magick convert -background none -auto-orient '/homelab/test-icons/test.ico' "${tmpdir}/ico2png/test.png" && \
    magick convert -background none -resize 100x100 -auto-orient '/homelab/test-icons/test.png' "${tmpdir}/png2png/test.png" && \
    rm -rf "${tmpdir}"

### App config ###

FROM yq AS urls_config_1
USER root
WORKDIR /homelab
ARG HOMELAB_APP_TYPE
ARG HOMELAB_ENV=dev
COPY ./docker-images/.shared/build-utils/parse-app-entry-utils.sh ./docker-images/favicons/parse-app-entry.sh /homelab/
# hadolint ignore=SC2016
RUN --mount=type=bind,source=./servers/,target=/homelab/servers,readonly \
    --mount=type=bind,source=./docker-compose/,target=/homelab/docker-compose,readonly \
    printf 'apps:\n' >'/homelab/app-entries.yml' && \
    find '/homelab/servers' -path '/homelab/servers/*/docker-apps/*' -mindepth 3 -maxdepth 3 -type d -not -name '.*' -print0 | xargs -0 -I% sh '/homelab/parse-app-entry.sh' % '/homelab/app-entries.yml' && \
    yq --in-place --yaml-output '.apps |= (sort_by(.app_type) | unique_by(.app_type))' '/homelab/app-entries.yml' && \
    yq --in-place --yaml-output --arg homelab_app_type "${HOMELAB_APP_TYPE}" '.apps |= map(select(.app_type == $homelab_app_type))' '/homelab/app-entries.yml' && \
    yq --in-place --yaml-output --arg homelab_env "${HOMELAB_ENV}" '.apps |= map(if (.proxy_urls | type) == "array" then .proxy_urls |= map(select(.env == null or .env == $homelab_env) | del(.env)) else . end)' '/homelab/app-entries.yml' && \
    yq '.' '/homelab/app-entries.yml' >'/homelab/apps.json'

FROM jinja AS urls_config_2
USER root
WORKDIR /homelab
COPY --from=urls_config_1 /homelab/apps.json /homelab/
COPY ./docker-images/favicons/urls.yml.j2 /homelab/
RUN jinja2 --strict './urls.yml.j2' './apps.json' --format json -o './urls.yml' && \
    if grep --quiet --fixed-strings 'ERROR:' './urls.yml' >/dev/null 2>&1; then \
        printf 'URLs config is not valid:\n' >&2 && \
        cat './urls.yml' >&2 && \
        exit 1; \
    fi

FROM yq AS urls_config_3
USER root
WORKDIR /homelab
COPY --from=urls_config_2 /homelab/urls.yml /homelab/
RUN yq '.' '/homelab/urls.yml' >'/homelab/urls.json'

### App ###

FROM node:26.13.1-slim@sha256:abe7e5a82b61a8ef67b315b85497c9e65173387ccf2f4a029248184b8e020be5 AS nodejs_build
USER root
WORKDIR /homelab
COPY ./docker-images/favicons/package-lock.json ./docker-images/favicons/package.json /homelab/
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm,sharing=shared,id=homelab_nodejs_npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --no-audit --no-fund --no-progress --no-save --loglevel=error --prefer-offline
COPY ./docker-images/favicons/tsconfig.json /homelab/
COPY ./docker-images/favicons/src/ /homelab/src/
RUN npm run build && \
    npx modclean --patterns default:safe --run --error-halt && \
    npx node-prune && \
    npm prune --production

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
COPY --from=nodejs_build /homelab/package.json /homelab/
COPY --from=nodejs_build /homelab/node_modules /homelab/node_modules
COPY --from=nodejs_build /homelab/dist /homelab/dist
COPY ./docker-images/favicons/icons /homelab/icons
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=imagemagick_final /homelab/imagemagick/ /homelab/imagemagick/
COPY --from=urls_config_3 /homelab/urls.json /homelab/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM gcr.io/distroless/nodejs26-debian13:latest@sha256:b462e87a3db156aea160dd8a5306b85d02c3061ca0e3194fe0af81282a830ab0 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
WORKDIR /homelab
ENV FAVICON_PASSWORD="" \
    HOMELAB_CONTAINER_NAME="favicons" \
    HOMELAB_CONTAINER_VARIANT="default" \
    NODE_OPTIONS="--dns-result-order=ipv4first" \
    PATH="/homelab/bin:/homelab/imagemagick/bin:${PATH}" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=5m --timeout=2s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"http://localhost:8080/.health\"}" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/dist/main.js" ]
