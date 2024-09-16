# Smtp4Dev

> Local smtp server for development

![diagram](../../docs/diagrams/out/apps/smtp4dev.png)

- GitHub: <https://github.com/rnwood/smtp4dev>
- DockerHub: <https://hub.docker.com/r/rnwood/smtp4dev>
- Docs guide: <https://mailosaur.com/blog/a-guide-to-smtp4dev>
- Docs installation <https://github.com/rnwood/smtp4dev/wiki/Installation>
- Docs configuration: <https://github.com/rnwood/smtp4dev/wiki/Configuration>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`
- \[Prod\] Add healthchecks monitor for `web-backup` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Setup `uptime-kuma` HTTP/HTTPS monitor
