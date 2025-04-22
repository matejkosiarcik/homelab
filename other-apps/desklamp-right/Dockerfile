# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_2: No need for healthcheck

FROM arduinoci/ci-arduino-cli:v1.2.2
WORKDIR /homelab
RUN arduino-cli core update-index && \
    arduino-cli core install arduino:mbed_rp2040
COPY libraries.txt ./
RUN xargs -n1 arduino-cli lib install <libraries.txt
COPY desklamp-right.ino ./desklamp-right/
RUN arduino-cli compile -b arduino:mbed_rp2040:pico desklamp-right
ENTRYPOINT ["bash"]
CMD []
