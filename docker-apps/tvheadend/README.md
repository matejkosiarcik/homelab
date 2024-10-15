# Tvheadend

![diagram](../../docs/diagrams/out/apps/tvheadend.png)

- Official docs: <https://docs.tvheadend.org/documentation>
- Official repository: <https://github.com/tvheadend/tvheadend>

---

- LinuxServer docs: <https://docs.linuxserver.io/images/docker-tvheadend>
- LinuxServer GitHub: <https://github.com/linuxserver/docker-tvheadend>
- LinuxServer DockerHub: <https://hub.docker.com/r/linuxserver/tvheadend>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor and configure `HOMELAB_HEALTHCHECK_URL` for:
    - `certificate-manager.env`

## After initial installation

- \[Prod\] Setup Tvheadend:
    - Finish "setup wizard" according to <https://docs.linuxserver.io/images/docker-tvheadend/#application-setup>, TL;DR: goto `Configuration > General > Base > Start Wizard`
- \[Prod\] Setup anonymous user, in order to allow jellyfin to load channel logos, accordingly:
    - ![anonymous user](./anonymous%20user.png)
