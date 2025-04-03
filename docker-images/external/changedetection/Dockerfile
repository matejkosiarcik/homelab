# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM dgtlmoon/changedetection.io:0.49.11
COPY ./external/changedetection/entrypoint.sh ./external/changedetection/healthcheck.py /homelab/
ENV HOMELAB_CONTAINER_NAME=changedetection \
    HOMELAB_CONTAINER_VARIANT=default \
    LOGGER_LEVEL=WARNING \
    TZ=Europe/Bratislava

HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "python3 /homelab/healthcheck.py || exit 1" ]

ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
CMD [ ]
