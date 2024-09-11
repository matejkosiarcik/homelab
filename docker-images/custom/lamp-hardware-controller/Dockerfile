# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.7-slim AS python-build
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        python3 python3-pip python3-dev build-essential >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./custom/lamp-hardware-controller/requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --no-cache-dir

FROM debian:12.7-slim AS prefinal
WORKDIR /homelab
COPY --from=python-build /homelab/python-vendor/ ./python-vendor/
COPY ./custom/lamp-hardware-controller/main.py ./

FROM debian:12.7-slim
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        curl python3 >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=lamp-hardware-controller \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost || exit 1" ]
ENTRYPOINT [ "python3", "/homelab/main.py" ]
