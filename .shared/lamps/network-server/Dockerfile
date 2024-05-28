FROM node:22.2.0-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --quiet
COPY src/ ./src/
COPY rollup.config.js tsconfig.json ./
RUN npm run build && \
    npx modclean --patterns default:safe --run --error-halt && \
    npx node-prune && \
    npm prune --production

FROM node:22.2.0-slim AS aggregator
WORKDIR /app
COPY --from=build /app/dist/ ./dist/
COPY --from=build /app/node_modules/ ./node_modules/
COPY --from=build /app/package.json ./

FROM node:22.2.0-slim
COPY --from=aggregator /app/ /app/
WORKDIR /app
ENV TZ=Europe/Bratislava
EXPOSE 80
EXPOSE 443
ENTRYPOINT [ "sh", "-c", "node /app/dist/main.js" ]
