# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM homeassistant/home-assistant:2025.1.1

# FROM alexxit/go2rtc:1.9.7 AS go2rtc

# FROM python:3.13.0-slim
# WORKDIR /homelab
# RUN apt-get update -qq && \
#     DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
#         autoconf bluez build-essential ca-certificates curl ffmpeg libatlas-base-dev libavcodec-dev libavcodec59 libavdevice-dev libavdevice59 libavfilter-dev libavfilter8 libavformat-dev libavformat59 libavutil-dev libavutil57 libffi-dev libjpeg-dev liblapack-dev liblapack3 libopenjp2-7 libpcap-dev libpcap0.8 libssl-dev libswresample-dev libswresample4 libswscale-dev libswscale6 libtiff6 libturbojpeg0-dev pkg-config tzdata zlib1g-dev && \
#     rm -rf /var/lib/apt/lists/* && \
#     useradd -rm homeassistant && \
#     mkdir /srv/homeassistant && \
#     chown homeassistant:homeassistant /srv/homeassistant
# COPY ./external/homeassistant/requirements.txt /srv/homeassistant/
# RUN python3 -m pip install --requirement /srv/homeassistant/requirements.txt --target /srv/homeassistant/python-vendor --quiet
# COPY --from=go2rtc /usr/local/bin/go2rtc /usr/local/bin/
# ENV PATH="/srv/homeassistant/python-vendor/bin:$PATH" \
#     PYTHONPATH=/srv/homeassistant/python-vendor
# WORKDIR /srv/homeassistant
ENV HOMELAB_CONTAINER_NAME=homeassistant \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8123 || exit 1" ]
# ENTRYPOINT [ "hass", "--config", "/config" ]
