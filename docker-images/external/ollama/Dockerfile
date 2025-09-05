FROM ollama/ollama:0.11.10
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab /homelab/ollama && \
    chown -R user:user /homelab
COPY --chown=user:user ./external/ollama/entrypoint.sh /homelab/
USER user
RUN ln -sf /homelab/ollama ~/.ollama
ENV HOMELAB_CONTAINER_NAME=ollama \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "sh", "-c", "bash -c ':> /dev/tcp/localhost/11434' || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
