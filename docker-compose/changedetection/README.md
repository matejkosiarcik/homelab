# Changedetection

![diagram](../../docs/diagrams/out/apps/changedetection.png)

## Docs

Changedetection:

- GitHub: <https://github.com/dgtlmoon/changedetection.io>
- DockerHub: <https://hub.docker.com/r/dgtlmoon/changedetection.io>
- Homepage: <https://changedetection.io>

SockPuppetBrowser (used for opening \[web\] sites):

- GitHub: <https://github.com/dgtlmoon/sockpuppetbrowser>
- DockerHub: <https://hub.docker.com/r/dgtlmoon/sockpuppetbrowser>

## Before initial installation

- Follow general [guide](../../docs/Checklist%20for%20new%20docker-apps.md)

## After initial installation

- Setup admin password in `/settings#general`
- Setup notifications (ntfy, mail):
    - ntfy: `ntfys://<token>@ntfy.matejhome.com/changedetection` - see also [Ntfy README.md](../ntfy/README.md)
    - gotify: `gotifys://gotify.matejhome.com/<token>` - see also [Gotify README.md](../gotify/README.md)
    - mail: `mailto://placeholder@matejhome.com?smtp=smtp4dev.matejhome.com&from=changedetection@matejhome.com&to=notifications@matejhome.com`
- Tweak settings:
    - Change `General > Time between checks`
    - Change `General > Jitter`
    - Enable `Fetching > sockpuppetbrowser`
    - Disble `UI Options > Open history in new tab`
    - Enable `Global Filters > Render anchor tag`
- Import watched URLs from backup
