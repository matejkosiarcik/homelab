# Homelab repository instructions

## Adding a service

Apply this checklist when adding a new application or completing a partially
implemented application. Inspect comparable services first and follow their
current conventions. Complete only the missing work; do not duplicate existing
services, configuration, integrations, or generated assets.

### Image

- Add the application image under `docker-images/<app>/`. Put the `Dockerfile`
  and files used only by that image (configuration, entrypoints, and similar
  assets) together in its directory.
- For split applications, use component directories such as
  `docker-images/<app>/frontend/Dockerfile` and
  `docker-images/<app>/backend/Dockerfile`.
- Keep the final image as lean as practical. Prefer a `scratch` or distroless
  final stage where compatible, use multi-stage builds to prepare/download the
  application, and copy only the required runtime artifacts into the final
  image.
- Follow existing Dockerfile conventions, especially creating and using the
  `homelab` user and `/homelab` as the image's main directory.
- Define a container `HEALTHCHECK`, normally by reusing the matching helper in
  `docker-images/.shared/healthchecks/`. Check for and preserve a useful
  upstream health check when one already exists.
- Dockerfiles are built with the repository root as their build context and
  must build for both `linux/amd64` and `linux/arm64/v8`.

### Compose, networking, and observability

- Add the application's Compose definition under `docker-compose/<app>/` and
  include `compose.yml`, `compose.override-dev.yml`,
  `compose.override-prod.yml`, and `config.yml`. Add a README with the diagram,
  upstream references, and any manual setup or operational steps.
- Start services from `docker-compose/.shared/compose.yml` templates whenever
  possible. Preserve their hardening defaults (dropped capabilities,
  read-only filesystem, no-new-privileges, init, and restrictive `tmpfs`), then
  grant only the writable paths or privileges the application requires.
- Reuse and extend shared services such as Apache and Certificator rather than
  recreating their responsibilities.
- Prefer local directory bind mounts for persistent data and logs. Store them
  under `app-data/<service>/<purpose>` (for example, `app-data/app/data`) and
  `app-logs/<service>/<purpose>` (for example,
  `app-logs/apache/healthcheck`).
- Apply least privilege to capabilities, mounts, and networks. Add external
  network access only when the application needs the internet or another local
  service. Use blackhole DNS for an application that needs IP access but no
  domain resolution; use internal DNS for local-only access without internet.
- Add the appropriate Gatus and Prometheus endpoints, following the patterns
  used by comparable Compose applications. Add applicable Healthchecks
  integration too.
- Keep the default network disabled (`driver: none`), expose web applications
  through the shared Apache service instead of directly publishing application
  ports, and declare internal or external networks explicitly when needed.

### User-facing integration and assets

- Add the service to the appropriate Homepage section.
- Determine the icon path used by the application. If it has no usable icon,
  select a suitable icon from `icons/`, add it to the favicon build script, and
  run that script.
- Regardless of the application's own icon, select a suitable `icons/` source
  for the diagram and Homepage icon sets, add it to their build scripts, run
  the necessary scripts, and use the resulting assets in those integrations.
- Add an application diagram in `docs/diagrams/src/apps/`, following nearby
  diagram conventions.

### Secrets and tests

- Update the secrets-creation helper for the application section and any
  secrets needed by consumers such as Prometheus and Gatus.
- Never directly edit stored SOPS secret YAML files. In the handoff, list the
  exact secret section and keys the user must add instead.
- Add tests following `tests/projects/tests/` conventions. Cover required
  application endpoints and every exposed port. For a UI, test page access;
  when authentication exists, include both successful and failed login tests.
- Register the deployed service and its instances in `tests/utils/apps.ts` so
  its tests can use the shared test helpers.

### Deployment instance

- Do not connect to, deploy to, restart, or otherwise modify the running
  physical servers (Odroids and Raspberry Pis).
- Add a server-specific application directory at
  `servers/<server>/docker-apps/<instance>/` only when the user explicitly
  requests deployment on that named server. Include the standard `Taskfile.yml`
  that imports `utils/app-helpers/Taskfile.yml` and `config/config.yml` with
  the instance's type or variant when needed. One deployment instance maps to
  one `docker-compose` stack.
- For a requested deployment instance, determine the highest IP already used in
  that server's `docker-apps/*/config/config.yml` files and assign the next IP
  address. Preserve the default domain unless a domain override is requested.
