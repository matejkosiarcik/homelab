# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM binwiederhier/ntfy:v2.12.0
COPY ./external/ntfy/setup.sh /homelab/
COPY ./external/ntfy/config/server.yml /etc/ntfy/server.yml
ENV HOMELAB_CONTAINER_NAME=ntfy \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "sh", "-c", "wget -q --tries=1 http://localhost/v1/health -O - | grep -Eo '\"healthy\"\\s*:\\s*true' || exit 1" ]
ENTRYPOINT [ "ntfy" ]
CMD [ "serve" ]
