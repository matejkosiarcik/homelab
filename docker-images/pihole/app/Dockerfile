# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest
# checkov:skip=CKV_DOCKER_8: Must run as root

### Dependencies ###

FROM debian:13.7-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_yq_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_yq_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION="ignore"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### App config ###

FROM yq AS dns_entries
USER root
WORKDIR /homelab
COPY ./servers/ /homelab/servers/
COPY ./docker-compose/ /homelab/docker-compose/
COPY ./docker-images/.shared/build-utils/parse-app-entry-utils.sh ./docker-images/pihole/app/parse-app-entry.sh /homelab/
COPY ./docker-images/pihole/app/extra-domains.txt /homelab/
RUN find '/homelab/servers' -path '/homelab/servers/*/docker-apps/*' -mindepth 3 -maxdepth 3 -type d -not -name '.*' -print0 | xargs -0 -I% sh '/homelab/parse-app-entry.sh' % '/homelab/app-domains.txt' && \
    cat '/homelab/app-domains.txt' '/homelab/extra-domains.txt' | sed -E 's~ *#.*$~~' | grep -Ev '^$' | sort --version-sort >'/homelab/custom-domains.txt'

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_pihole_user_setup_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_pihole_user_setup_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~pihole~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~pihole~' | sponge --append /etc/passwd

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
ARG SETUP_SCRIPT=default
COPY ./docker-images/pihole/app/setup-${SETUP_SCRIPT}.sh /homelab/setup.sh
COPY --from=dns_entries /homelab/custom-domains.txt /homelab/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --chmod=0777 ./docker-images/pihole/app/capsh.sh /usr/sbin/capsh
COPY --chmod=0777 ./docker-images/pihole/app/setcap.sh /usr/sbin/setcap

### Final ###

FROM pihole/pihole:2026.07.2
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
RUN chown -R homelab:homelab /macvendor.db /etc/.pihole /etc/pihole /usr/local/bin/pihole /usr/bin/pihole-FTL && \
    mv /usr/sbin/setcap /usr/sbin/setcap-original && \
    mv /usr/sbin/capsh /usr/sbin/capsh-original
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /usr/sbin/capsh /usr/sbin/capsh
COPY --from=prefinal --chown=homelab:homelab /usr/sbin/setcap /usr/sbin/setcap
ARG GID=1000
ARG UID=1000
ENV DHCP_ACTIVE="false" \
    DNSMASQ_USER="homelab" \
    FTLCONF_dns_blockTTL="600" \
    FTLCONF_dns_domain="matejhome.com" \
    FTLCONF_dns_domainNeeded="true" \
    FTLCONF_dns_ignoreLocalhost="false" \
    FTLCONF_dns_listeningMode="all" \
    FTLCONF_dns_piholePTR="HOSTNAMEFQDN" \
    FTLCONF_dns_rateLimit_count="0" \
    FTLCONF_dns_rateLimit_interval="0" \
    FTLCONF_dns_replyWhenBusy="BLOCK" \
    FTLCONF_dns_upstreams="1.1.1.1;8.8.8.8;9.9.9.9" \
    FTLCONF_misc_dnsmasq_lines="local-ttl=600" \
    FTLCONF_misc_nice="-999" \
    FTLCONF_misc_privacylevel="0" \
    FTLCONF_webserver_api_allow_destructive="false" \
    FTLCONF_webserver_domain="pihole-placeholder" \
    FTLCONF_webserver_interface_theme="default-darker" \
    HOMELAB_CONTAINER_NAME="pihole" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PIHOLE_GID="${GID}" \
    PIHOLE_UID="${UID}" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:80/admin" ]
