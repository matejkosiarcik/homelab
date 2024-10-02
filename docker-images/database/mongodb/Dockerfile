# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM mongo:8.0.0
COPY ./database/mongodb/init-mongo-default.js /docker-entrypoint-initdb.d/init-mongo.js
COPY ./database/mongodb/healthcheck.sh /homelab/
ENV DBNAME=database \
    HOMELAB_CONTAINER_NAME=mongodb \
    HOMELAB_CONTAINER_VARIANT=default \
    PORT=27017 \
    TZ=Europe/Bratislava \
    USER=mongo
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "/homelab/healthcheck.sh" ]
CMD [ "--auth", "--quiet", "--logpath", "/dev/null" ]
