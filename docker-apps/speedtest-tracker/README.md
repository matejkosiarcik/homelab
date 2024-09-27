# SpeedTest Tracker

![diagram](../../docs/diagrams/out/apps/speedtest-tracker.png)

- Main page: <https://speedtest-tracker.dev>
- Docs: <https://docs.speedtest-tracker.dev>
- GitHub: <https://github.com/alexjustesen/speedtest-tracker>
- GitHub: <https://github.com/linuxserver/docker-speedtest-tracker>
- DockerHub: <https://hub.docker.com/r/linuxserver/speedtest-tracker>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor and configure `HOMELAB_HEALTHCHECK_URL` for:
    - `certificate-manager.env`

## After initial installation

- Change admin credentials (defaults are `admin@example.com`/`password`)
- \[Prod\] Setup `uptime-kuma` monitoring:
    - IP (ping) monitor
    - TCP monitor for all open ports
    - HTTP/HTTPS monitor
    - HTTPS JSON query monitor for basic API operation
