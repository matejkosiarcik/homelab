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
    - `web-admin-setup.env`
    - `web-export.env`
- \[Prod\] Configure `ADMIN_EMAIL` for:
    - `speedtest-tracker.env`
    - `web-admin-setup.env`
    - `web-export.env`

## After initial installation

- \[Prod\] Setup `uptime-kuma` HTTP/HTTPS monitor
- \[Prod\] Setup `uptime-kuma` HTTPS JSON query monitor
