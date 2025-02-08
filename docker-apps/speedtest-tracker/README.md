# SpeedTest Tracker

![diagram](../../docs/diagrams/out/apps/speedtest-tracker.png)

## Docs

Speedtest Tracker (official):

- Main page: <https://speedtest-tracker.dev>
- Docs: <https://docs.speedtest-tracker.dev>
- GitHub: <https://github.com/alexjustesen/speedtest-tracker>

LinuxServer (unofficial):

- LinuxServer docs: <https://docs.linuxserver.io/images/docker-speedtest-tracker/>
- LinuxServer GitHub: <https://github.com/linuxserver/docker-speedtest-tracker>
- LinuxServer DockerHub: <https://hub.docker.com/r/linuxserver/speedtest-tracker>

## Before initial installation

- \[Prod\] Create secrets in Vaultwarden
    - Note: Get `APP_KEY` from <https://speedtest-tracker.dev>
    - Add healthchecks monitor and save URL
- \[All\] Update local secrets

## After initial installation

- Setup speed tresholds
- Add webhook to healthchecks (always)
- Add webhook to mail/ntfy (on treshold)
