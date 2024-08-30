# SpeedTest Tracker

- Main page: <https://speedtest-tracker.dev>
- Docs: <https://docs.speedtest-tracker.dev>
- GitHub: <https://github.com/alexjustesen/speedtest-tracker>
- GitHub: <https://github.com/linuxserver/docker-speedtest-tracker>
- DockerHub: <https://hub.docker.com/r/linuxserver/speedtest-tracker>

## Before initial installation

- \[All\] Create base secrets
- \[All\] Visit <https://speedtest-tracker.dev> and configure `APP_KEY` for `main-app`
- \[Prod\] Add healthchecks monitor and configure `HOMELAB_HEALTHCHECK_URL` for:
    - `certificate-manager.env`
    - `web-admin-setup.env`
    - `web-export.env`
- \[Prod\] Configure `ADMIN_EMAIL` for:
    - `main-app.env`
    - `web-admin-setup.env`
    - `web-export.env`

## After initial installation

- \[All\] Setup custom admin _username_ and _password_
- \[Prod\] Setup `uptime-kuma` HTTP/HTTPS monitor
- \[Prod\] Setup `uptime-kuma` HTTPS JSON query monitor
