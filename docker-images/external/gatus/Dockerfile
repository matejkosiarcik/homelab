# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM golang:1.24.4-alpine AS healthcheck-builder
WORKDIR /homelab
COPY ./.shared/healthcheck-placeholder/main.go ./.shared/healthcheck-placeholder/go.mod ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

FROM twinproduction/gatus:v5.19.0
COPY ./external/gatus/config.yml /config/config.yaml
COPY --from=healthcheck-builder /homelab/healthcheck /homelab/healthcheck
ENV GATUS_DELAY_START_SECONDS=0 \
    HOMELAB_CONTAINER_NAME=gatus \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava

# There isn't a way to do a real healthcheck inside this container, see: https://github.com/TwiN/gatus/issues/711
# So instead we just "fake" it and provide a dummy placeholder healthcheck program
HEALTHCHECK --interval=10s --start-period=20s --timeout=2s --retries=1 CMD [ "/homelab/healthcheck" ]
