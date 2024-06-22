# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM node:22.3.0-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
COPY patches/ ./patches/
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm
#  --no-progress --no-audit --quiet
COPY backend/ ./backend/
COPY frontend/ ./frontend/
COPY terser.json tsconfig.json ./
RUN npm run build && \
    npx modclean --patterns default:safe --run --error-halt && \
    npx node-prune && \
    npm prune --production

FROM node:22.3.0-slim AS aggregator
WORKDIR /app
COPY --from=build /app/dist/ ./dist/
COPY --from=build /app/node_modules/ ./node_modules/
COPY --from=build /app/package.json ./

FROM node:22.3.0-slim
COPY --from=aggregator /app/ /app/
WORKDIR /app
ENV TZ=Europe/Bratislava
EXPOSE 80
EXPOSE 443
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost/status || exit 1" ]
ENTRYPOINT [ "sh", "-c", "node /app/dist/backend/main.js" ]
