# checkov:skip=CKV_DOCKER_8: Must run as root
# TODO: Investigate if it is possible to run as non-root
# checkov:skip=CKV_DOCKER_2: No need for healthcheck

FROM arduinoci/ci-arduino-cli:v1.6.0@sha256:d4fdf0bc45ae10499084aaeb825e51db847bd068246a28b60a00a35a4c092593 AS final
ENV PATH="/homelab/bin:${PATH}"
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
WORKDIR /homelab
RUN arduino-cli core update-index && \
    arduino-cli core install arduino:mbed_rp2040
COPY libraries.txt /homelab/
RUN xargs -n1 arduino-cli lib install <libraries.txt
COPY desklamp-left.ino /homelab/desklamp-left/
RUN arduino-cli compile -b arduino:mbed_rp2040:pico desklamp-left
ENTRYPOINT ["bash"]
CMD []
