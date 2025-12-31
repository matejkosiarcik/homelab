# checkov:skip=CKV_DOCKER_8: Must run as root
# TODO: Investigate if it is possible to run as non-root
# checkov:skip=CKV_DOCKER_2: No need for healthcheck

FROM arduinoci/ci-arduino-cli:v1.4.0
USER root
WORKDIR /homelab
RUN arduino-cli core update-index && \
    arduino-cli core install arduino:mbed_rp2040
COPY libraries.txt ./
RUN xargs -n1 arduino-cli lib install <libraries.txt
COPY desklamp-right.ino ./desklamp-right/
RUN arduino-cli compile -b arduino:mbed_rp2040:pico desklamp-right
ENTRYPOINT ["bash"]
CMD []
