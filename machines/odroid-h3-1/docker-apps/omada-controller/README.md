# TP-Link Omada SDN Controller

For general `omada-controller` docs see [/docker-images/external/omada-controller/README.md](../../../../docker-images/external/omada-controller/README.md)

## Installation

Before installation prepare following files:

- `/private/webui-backup.env` - Contains following environment variables:
    - `USERNAME` - UI admin account username
    - `PASSWORD` - UI admin account password
    - `HEALTHCHECK_URL` - Full URL (protocol, domain/host, ping uuid) to Healthchecks ping check

## After First Installation

- Setup admin account
- General config and settings customization
- Setup SMTP server for email
- Send automatic backups via SFTP
- Send logs to remote syslog server
