# SpeedTest Tracker

- Main page: <https://speedtest-tracker.dev>
- Docs: <https://docs.speedtest-tracker.dev>
- GitHub: <https://github.com/alexjustesen/speedtest-tracker>
- GitHub: <https://github.com/linuxserver/docker-speedtest-tracker>
- DockerHub: <https://hub.docker.com/r/linuxserver/speedtest-tracker>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`
- \[Prod\] Add healthchecks monitor for `web-backup` and configure `HOMELAB_HEALTHCHECK_URL`
- \[All\] Visit <https://speedtest-tracker.dev> and configure `APP_KEY` for `main-app`

## After initial installation

- \[Prod\] Setup `uptime-kuma` monitor for HTTP and HTTPS
