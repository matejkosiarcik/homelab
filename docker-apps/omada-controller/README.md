# TP-Link Omada SDN Controller

- GitHub: <https://github.com/mbentley/docker-omada-controller>
- DockerHub: <https://hub.docker.com/r/mbentley/omada-controller>

## Before initial installation

- [Prod] Add healthchecks monitor for `web-backup` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- [All] Setup admin _username_ and _password_
- [Prod] Setup settings
  - General config and settings customization
  - Setup SMTP server for email
  - Send automatic backups via SFTP
  - Send logs to remote syslog server
