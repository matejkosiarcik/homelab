# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM mongo:8.0.10
COPY ./external/mongodb/init-mongo-default.js /docker-entrypoint-initdb.d/init-mongo.js
COPY ./external/mongodb/healthcheck.sh /homelab/
ENV HOMELAB_CONTAINER_NAME=mongodb \
    HOMELAB_CONTAINER_VARIANT=default \
    MONGO_DBNAME=database \
    MONGO_USER=mongo \
    PORT=27017 \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "/homelab/healthcheck.sh" ]
CMD [ "--auth", "--quiet", "--logpath", "/dev/null" ]
