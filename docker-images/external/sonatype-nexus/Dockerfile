# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM sonatype/nexus3:3.71.0
ENV TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=150s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8081 || exit 1" ]
