# Uptime Kuma

- GitHub: <https://github.com/louislam/uptime-kuma>
- DockerHub: <https://hub.docker.com/r/louislam/uptime-kuma>
- Docs: <https://github.com/louislam/uptime-kuma/wiki>

## Installation

Before installation prepare following files:

- `/private/app-backup.env` - Contains following environment variables:
    - `USERNAME` - UI admin account username
    - `PASSWORD` - UI admin account password
    - `HEALTHCHECK_URL` - Full URL (protocol, domain/host, ping uuid) to Healthchecks ping check

## After Installation

- Setup Timezone in settings
- Setup Primary Base URL
- Disallow automatic updates
- Setup Email notifications (SMTP)
- Modify statistics history persistant interval
