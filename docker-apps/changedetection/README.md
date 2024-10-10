# Changedetection

![diagram](../../docs/diagrams/out/apps/changedetection.png)

- GitHub: <https://github.com/dgtlmoon/changedetection.io>
- DockerHub: <https://hub.docker.com/r/dgtlmoon/changedetection.io>
- Homepage: <https://changedetection.io>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Setup admin password in `/settings#general`
- \[Prod\] Setup notifications (ntfy)
- \[Prod\] Setup `uptime-kuma` monitoring:
    - IP (ping) monitor
    - TCP monitor for all open ports
    - HTTP/HTTPS monitor
- \[Prod\] Create any necessary Auth tokens

## Publishing notifications

For publishing notifications to ntfy (see also: https://github.com/caronc/apprise/wiki/Notify_ntfy):

```txt
ntfy://publisher:<password>@<domain>/<topic>
```

Alternatively you can also publish via email (see also https://github.com/caronc/apprise/wiki/Notify_email):

```txt
mailto://ntfy-<topic>+<token>@<domain>
```

Obviously replace `<domain>`, `<passowrd>`, `<token>` and `<topic>` with their respective values (remove enclosing `<>`).
