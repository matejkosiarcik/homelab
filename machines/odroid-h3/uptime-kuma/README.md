# Uptime Kuma

For general `uptime-kuma` docs see [/components/uptime-kuma/README.md](../../../components/uptime-kuma/README.md)

## Installation

Before installation prepare following files:

- `/private/webui-backup.env` - Contains following environment variables:
    - `USERNAME` - UI admin account username
    - `PASSWORD` - UI admin account password
    - `HEALTHCHECK_URL` - Full URL (protocol, domain/host, ping uuid) to Healthchecks ping check

## After Installation

- Setup Timezone in settings
- Setup Primary Base URL
- Disallow automatic updates
- Setup Email notifications (SMTP)
- Modify statistics history persistant interval
