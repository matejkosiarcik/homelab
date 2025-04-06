# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_8: Ignore root user

FROM python:3.13.2-slim AS python
WORKDIR /homelab
ENV PIP_ROOT_USER_ACTION=ignore
COPY ./external/prometheus/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./external/prometheus/prometheus.json ./external/prometheus/prometheus.yml.j2 ./
RUN jinja2 prometheus.yml.j2 prometheus.json --format json -o prometheus.yml

FROM debian:12.10-slim AS prefinal
WORKDIR /homelab
COPY ./external/prometheus/web.yml ./external/prometheus/entrypoint.sh /etc/prometheus/
COPY --from=python ./homelab/prometheus.yml /etc/prometheus/prometheus.yml

FROM prom/prometheus:v3.2.1
COPY --from=prefinal /etc/prometheus/web.yml /etc/prometheus/prometheus.yml /etc/prometheus/entrypoint.sh /etc/prometheus/
ENV HOMELAB_CONTAINER_NAME=prometheus \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://admin:$PROMETHEUS_ADMIN_PASSWORD@localhost:9090 || exit 1" ]
# hadolint ignore=DL3002
USER root
ENTRYPOINT [ "sh", "/etc/prometheus/entrypoint.sh" ]
CMD []
