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

- Follow general [guide](../../docs/Checklist%20for%20new%20docker-apps.md)

## After initial installation

- Setup speed tresholds
- Add (always) webhook to healthchecks
    - `https://healthchecks.home.matejkosiarcik.com/ping/<ping-key>/speedtest-tracker-app`
- Add (treshold) webhook to ntfy / gotify / smtp notifications
    - `https://ntfy.home.matejkosiarcik.com`, topic: `speedtest-tracker`, username: `publisher`, password: `<password>`
    - `https://gotify.home.matejkosiarcik.com/message?token=<token>`
    - `system@speedtest-tracker.home.matejkosiarcik.com`
