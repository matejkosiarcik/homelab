# Changedetection

![diagram](../../docs/diagrams/out/apps/changedetection.png)

- GitHub: <https://github.com/dgtlmoon/changedetection.io>
- DockerHub: <https://hub.docker.com/r/dgtlmoon/changedetection.io>
- Homepage: <https://changedetection.io>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Setup admin password in `/settings#general`
- \[Prod\] Setup notifications (ntfy, smtp)
    - For ntfy see [ntfy/README.md](../ntfy/README.md)
