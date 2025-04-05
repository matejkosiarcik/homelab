# checkov:skip=CKV_DOCKER_3: No need for explicit user

# FROM actualbudget/actual-server:25.3.1 AS actualbudget-original

# FROM debian:12.10-slim AS actualbudget-patch
# WORKDIR /homelab
# RUN apt-get update && \
#     DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
#         git >/dev/null && \
#     rm -rf /var/lib/apt/lists/*
# COPY ./external/actualbudget/app.js.patch ./
# COPY --from=actualbudget-original /app/src/app.js ./
# RUN git apply app.js.patch

FROM actualbudget/actual-server:25.4.0
# COPY --from=actualbudget-patch /homelab/app.js /app/src/app.js
COPY ./external/actualbudget/healthcheck.js /homelab/
ENV ERR_ERL_UNEXPECTED_X_FORWARDED_FOR=false \
    HOMELAB_CONTAINER_NAME=actual-budget \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "node /homelab/healthcheck.js || exit 1" ]
