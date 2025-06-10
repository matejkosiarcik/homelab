# syntax = edrevo/dockerfile-plus
# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in
# checkov:skip=CKV_DOCKER_7: False positive for ":latest" tag with included build stages

### Favicon ####

# INCLUDE+ ./.shared/build-stages/imagemagick/Dockerfile
# INCLUDE+ ./.shared/build-stages/oxipng/Dockerfile
# INCLUDE+ ./.shared/build-stages/png2ico/Dockerfile
# INCLUDE+ ./.shared/build-stages/zopflipng/Dockerfile

# FROM gotify/server:2.6.3 AS favicon-1
# WORKDIR /homelab
# RUN (/app/gotify-app &) && \
#     sleep 1 && \
#     curl --location --fail --silent --show-error --output ./favicon-196x196.png http://localhost/static/favicon-196x196.png

# FROM imagemagick AS favicon-2
# WORKDIR /homelab
# COPY --from=favicon-1 /homelab/favicon-196x196.png ./
# RUN file 'favicon-196x196.png' | grep 'PNG image data' && \
#     test "$(wc -c <'favicon-196x196.png')" -gt 0 && \
#     convert -background none 'favicon-196x196.png' -resize 32x32 -density 1200 'favicon-32x32.png' && \
#     convert -background none 'favicon-196x196.png' -resize 16x16 -density 1200 'favicon-16x16.png'

# FROM oxipng AS favicon-3
# WORKDIR /homelab
# COPY --from=favicon-2 /homelab/favicon-16x16.png /homelab/favicon-32x32.png ./
# RUN oxipng --opt max --strip safe favicon-16x16.png favicon-32x32.png

# # hadolint ignore=DL3029
# FROM --platform=linux/amd64 zopflipng AS favicon-4
# WORKDIR /homelab
# COPY --from=favicon-3 /homelab/favicon-16x16.png /homelab/favicon-32x32.png ./
# RUN find . -type f -name '*.png' -maxdepth 1 | while read -r file; do \
#         zopflipng --iterations=100 --filters=01234mepb --lossy_8bit --lossy_transparent -y "$file" "$file" && \
#     true; done

# FROM png2ico AS favicon-5
# WORKDIR /homelab
# COPY --from=favicon-4 /homelab/favicon-16x16.png /homelab/favicon-32x32.png ./
# RUN python3 ./png2ico/png2ico.py favicon-16x16.png favicon-32x32.png -o favicon.ico

### Final ####

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
# COPY --from=favicon-5 /homelab/favicon.ico ./favicon/

FROM gotify/server:2.6.3
COPY ./external/gotify/config.yml /etc/gotify/config.yml
COPY --from=prefinal /homelab/ /homelab/
RUN chmod go-rw /etc/gotify/config.yml
ENV HOMELAB_CONTAINER_NAME=gotify \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
