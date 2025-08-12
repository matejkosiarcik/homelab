# checkov:skip=CKV_DOCKER_3: User unnecessary
# checkov:skip=CKV_DOCKER_2: Healthcheck unnecessary

FROM --platform=$BUILDPLATFORM debian:13.0-slim AS oxipng-yq
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/yq/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.shared/dependencies/oxipng/Cargo.toml ./
RUN tomlq -r '."dev-dependencies" | to_entries | map("\(.key) \(.value)")[]' Cargo.toml >cargo-dependencies.txt

FROM rust:1.88.0-slim-bookworm AS oxipng
WORKDIR /homelab
COPY --from=oxipng-yq /homelab/cargo-dependencies.txt ./
ENV CARGO_PROFILE_RELEASE_LTO=true \
    CARGO_PROFILE_RELEASE_PANIC=abort \
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 \
    CARGO_PROFILE_RELEASE_OPT_LEVEL=s \
    RUSTFLAGS='-Cstrip=symbols -Clink-args=-Wl,--build-id=none'
RUN while read -r package version; do \
        cargo install "$package" --quiet --force --version "$version" --root "$PWD/cargo" && \
    true; done <cargo-dependencies.txt
ENV PATH="/homelab/cargo/bin:$PATH"
