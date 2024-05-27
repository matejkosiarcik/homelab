# checkov:skip=CKV_DOCKER_8: allow root user

FROM debian:12.5 AS build
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends python3 python3-pip python3-dev build-essential >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --requirement requirements.txt --target vendor --quiet

FROM debian:12.5
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends python3 >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=build /app/vendor/ ./vendor/
COPY main.py ./
ENV PATH="/app/vendor/bin:$PATH" \
    PYTHONPATH=/app/vendor \
    TZ=Europe/Bratislava
USER root
ENTRYPOINT [ "python3", "/app/main.py" ]
