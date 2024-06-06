# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM mongo:7.0.11
COPY init-mongo.js /docker-entrypoint-initdb.d/init-mongo.js
ENV TZ=Europe/Bratislava \
    DBNAME=database \
    USER=mongo \
    PORT=27017
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "bash", "-c", "printf 'show databases\n' | mongosh \"localhost:${PORT}/${DBNAME}\" --username \"${USER}\" --password \"$(cat /.homelab/database-password.txt)\" --quiet || exit 1" ]
CMD ["--auth"]
