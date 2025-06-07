# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

### Favicon dependencies ####

FROM python:3.13.4-slim AS png2ico-gitman
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/gitman/requirements.txt ./
ENV PIP_ROOT_USER_ACTION=ignore
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.shared/dependencies/png2ico/gitman.yml ./
RUN gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

FROM python:3.13.4-slim AS png2ico
WORKDIR /homelab
COPY ./.shared/dependencies/image-tools/requirements.txt ./
ENV PIP_ROOT_USER_ACTION=ignore
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY --from=png2ico-gitman /homelab/gitman-repositories/png2ico ./png2ico/

FROM debian:12.11-slim AS imagemagick
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        imagemagick && \
    rm -rf /var/lib/apt/lists/*

# Must hardcode x86_64, because zoplipng is only built for this architecture
# hadolint ignore=DL3029
FROM --platform=linux/amd64 node:23.11.1-slim AS zopflipng
WORKDIR /homelab
COPY ./.shared/dependencies/zopflipng/package.json ./.shared/dependencies/zopflipng/package-lock.json ./
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm prune --production
ENV PATH="/homelab/node_modules/.bin:$PATH"

FROM --platform=$BUILDPLATFORM debian:12.11-slim AS yq
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/yq/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

FROM yq AS oxipng-version
WORKDIR /homelab
COPY ./.shared/dependencies/oxipng/Cargo.toml ./
RUN tomlq -r '."dev-dependencies" | to_entries | map("\(.key) \(.value)")[]' Cargo.toml >cargo-dependencies.txt

FROM rust:1.87.0-slim-bookworm AS oxipng
WORKDIR /homelab
COPY --from=oxipng-version /homelab/cargo-dependencies.txt ./
ENV CARGO_PROFILE_RELEASE_LTO=true \
    CARGO_PROFILE_RELEASE_PANIC=abort \
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 \
    CARGO_PROFILE_RELEASE_OPT_LEVEL=s \
    RUSTFLAGS='-Cstrip=symbols -Clink-args=-Wl,--build-id=none'
RUN while read -r package version; do \
        cargo install "$package" --quiet --force --version "$version" --root "$PWD/cargo" && \
    true; done <cargo-dependencies.txt
ENV PATH="/homelab/cargo/bin:$PATH"

### Favicon ####

FROM gotify/server:2.6.3 AS gotify-favicon-original
WORKDIR /homelab
RUN (/app/gotify-app &) && \
    sleep 1 && \
    curl --location --fail --silent --show-error --output ./favicon-196x196.png http://localhost/static/favicon-196x196.png

FROM imagemagick AS favicon-1
WORKDIR /homelab
COPY --from=gotify-favicon-original /homelab/favicon-196x196.png ./
RUN convert -background none ./favicon-196x196.png -resize 32x32 -density 1200 ./favicon-32x32.png && \
    convert -background none ./favicon-196x196.png -resize 16x16 -density 1200 ./favicon-16x16.png

FROM oxipng AS favicon-2
WORKDIR /homelab
COPY --from=favicon-1 /homelab/favicon-16x16.png /homelab/favicon-32x32.png ./
RUN oxipng --opt max --strip safe favicon-16x16.png favicon-32x32.png

# hadolint ignore=DL3029
FROM --platform=linux/amd64 zopflipng AS favicon-3
WORKDIR /homelab
COPY --from=favicon-2 /homelab/favicon-16x16.png /homelab/favicon-32x32.png ./
RUN find . -type f -name '*.png' -maxdepth 1 | while read -r file; do \
        zopflipng --iterations=100 --filters=01234mepb --lossy_8bit --lossy_transparent -y "$file" "$file" && \
    true; done

FROM png2ico AS favicon-4
WORKDIR /homelab
COPY --from=favicon-3 /homelab/favicon-16x16.png /homelab/favicon-32x32.png ./
RUN python3 ./png2ico/png2ico.py favicon-16x16.png favicon-32x32.png -o favicon.ico

### Final ####

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
COPY --from=favicon-4 /homelab/favicon.ico ./favicon/

FROM gotify/server:2.6.3
COPY ./external/gotify/config.yml /etc/gotify/config.yml
COPY --from=prefinal /homelab/ /homelab/
RUN chmod go-rw /etc/gotify/config.yml
ENV HOMELAB_CONTAINER_NAME=gotify \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
