# checkov:skip=CKV_DOCKER_3: User unnecessary
# checkov:skip=CKV_DOCKER_2: Healthcheck unnecessary

# Must hardcode x86_64, because zoplipng is only built for this architecture
# hadolint ignore=DL3029
FROM --platform=linux/amd64 node:24.6.0-slim AS zopflipng
WORKDIR /homelab
COPY ./.shared/dependencies/zopflipng/package.json ./.shared/dependencies/zopflipng/package-lock.json ./
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm prune --production
ENV PATH="/homelab/node_modules/.bin:$PATH"
