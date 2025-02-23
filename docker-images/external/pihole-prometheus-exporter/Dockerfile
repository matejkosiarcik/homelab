# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM golang:1.24.0-alpine3.20 AS healthcheck-builder
WORKDIR /homelab
COPY ./.shared/healthcheck-placeholder/main.go ./.shared/healthcheck-placeholder/go.mod ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

# hadolint ignore=DL3007
FROM ekofr/pihole-exporter:v0.4.0
COPY --from=healthcheck-builder /homelab/healthcheck /homelab/healthcheck
ENV HOMELAB_CONTAINER_NAME=pihole-prometheus-exporter \
    HOMELAB_CONTAINER_VARIANT=default \
    PIHOLE_PROTOCOL=http \
    PORT=80 \
    TZ=Europe/Bratislava

# There isn't a way to do a real healthcheck inside this container, see: https://github.com/TwiN/gatus/issues/711
# So instead we just "fake" it and provide a dummy placeholder healthcheck program
HEALTHCHECK --interval=5s --start-period=20s --timeout=2s --retries=1 CMD [ "/homelab/healthcheck" ]
