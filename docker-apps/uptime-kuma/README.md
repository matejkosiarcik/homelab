# Uptime Kuma

- GitHub: <https://github.com/louislam/uptime-kuma>
- DockerHub: <https://hub.docker.com/r/louislam/uptime-kuma>
- Docs: <https://github.com/louislam/uptime-kuma/wiki>

## Before initial installation

- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`
- \[Prod\] Add healthchecks monitor for `web-backup` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[All\] Setup admin _username_ and _password_
- \[Prod\] Settings setup:
    - Setup timezone
    - Setup Primary Base URL
    - Disallow automatic updates
    - Setup Email notifications (SMTP)
    - Modify statistics history persistant interval
- \[Prod\] Setup self HTTP/HTTPS monitor
