# Ntfy

![diagram](../../docs/diagrams/out/apps/ntfy.png)

- GitHub: <https://github.com/binwiederhier/ntfy>
- DockerHub: <https://hub.docker.com/r/binwiederhier/ntfy>
- Docs: <https://docs.ntfy.sh>
- Install guide: <https://docs.ntfy.sh/install>
- Install guide - docker: <https://docs.ntfy.sh/install/#docker>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Configure basic settings
- \[Prod\] Setup `uptime-kuma` monitoring:
    - IP (ping) monitor
    - TCP monitor for all open ports
    - HTTP/HTTPS monitor
