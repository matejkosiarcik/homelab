# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM couchdb:3.5.0
# printf '%s\n' "find /opt/couchdb/etc/local.d-tmp -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R /opt/couchdb/etc/local.d-tmp/\$(basename \$1) /opt/couchdb/etc/local.d/\$(basename \$1)' - {} \;" >/homelab/docker-entrypoint-extra.sh && \
COPY ./external/couchdb/jwt.ini /opt/couchdb/etc/local.d/
COPY ./external/couchdb/docker-entrypoint-extra.sh /homelab/
RUN head -n 1 /docker-entrypoint.sh >/homelab/docker-entrypoint-shebang.sh && \
    tail -n +2 /docker-entrypoint.sh >/homelab/docker-entrypoint-without-shebang.sh && \
    cat /homelab/docker-entrypoint-shebang.sh /homelab/docker-entrypoint-extra.sh /homelab/docker-entrypoint-without-shebang.sh >/docker-entrypoint.sh && \
    rm -rf /homelab
ENV COUCHDB_USER=admin \
    HOMELAB_CONTAINER_NAME=couchdb \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:5984/_up || exit 1" ]
