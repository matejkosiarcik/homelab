# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM debian:12.6-slim AS build
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends python3 python3-pip python3-dev build-essential >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --no-cache-dir

FROM debian:12.6-slim
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends python3 >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=build /app/python-vendor/ ./python-vendor/
COPY main.py ./
ENV PATH="/app/vendor/bin:$PATH" \
    PYTHONPATH=/app/python-vendor \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost || exit 1" ]
ENTRYPOINT [ "python3", "/app/main.py" ]
