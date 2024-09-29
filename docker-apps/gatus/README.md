# Gatus

![diagram](../../docs/diagrams/out/apps/gatus.png)

- GitHub: <https://github.com/TwiN/gatus?tab=readme-ov-file#docker>
- DockerHub: <https://hub.docker.com/r/twinproduction/gatus>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Setup `uptime-kuma` monitoring:
    - IP (ping) monitor
    - TCP monitor for all open ports
    - HTTP/HTTPS monitor
