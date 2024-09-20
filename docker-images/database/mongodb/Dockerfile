# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM mongo:8.0.0
COPY ./database/mongodb/init-mongo.js /docker-entrypoint-initdb.d/init-mongo.js
ENV HOMELAB_CONTAINER_NAME=mongodb \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava \
    DBNAME=database \
    USER=mongo \
    PORT=27017
HEALTHCHECK --interval=5s --start-period=20s --timeout=2s --retries=1 CMD [ "bash", "-c", "printf 'show databases\n' | mongosh \"localhost:${PORT}/${DBNAME}\" --username \"${USER}\" --password \"$(cat /homelab/mongodb-password.txt)\" --quiet || exit 1" ]
CMD [ "--auth", "--quiet", "--logpath", "/dev/null" ]
