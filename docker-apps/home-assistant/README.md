# Home Assistant

![diagram](../../docs/diagrams/out/apps/home-assistant.png)

- Generic installation tutorial: <https://www.home-assistant.io/installation>
- Container installation tutorial: <https://www.home-assistant.io/installation/linux#install-home-assistant-container>
- Configuration guide: <https://www.home-assistant.io/docs/configuration>
- DockerHub: <https://hub.docker.com/r/homeassistant/home-assistant>

---

- LinuxServer docs: <https://docs.linuxserver.io/images/docker-homeassistant>
- LinuxServer DockerHub: <https://hub.docker.com/r/linuxserver/homeassistant>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `web-backup` and configure `HOMELAB_HEALTHCHECK_URL`
- _TBD_

## After initial installation

- \[Prod\] Configure settings
- \[Prod\] Connect smart devices
- \[Prod\] Setup 2FA - <https://www.home-assistant.io/docs/authentication/multi-factor-auth>
- \[Prod\] Setup `uptime-kuma` monitoring:
    - IP (ping) monitor
    - TCP monitor for all open ports
    - HTTP/HTTPS monitor
    - TBD: HTTPS JSON query monitor for basic API operation?
