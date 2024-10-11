# Ntfy

![diagram](../../docs/diagrams/out/apps/ntfy.png)

- GitHub: <https://github.com/binwiederhier/ntfy>
- DockerHub: <https://hub.docker.com/r/binwiederhier/ntfy>
- Docs: <https://docs.ntfy.sh>
- Install guide: <https://docs.ntfy.sh/install>
- Install guide - docker: <https://docs.ntfy.sh/install/#docker>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Configure basic settings
- \[Prod\] Create any necessary Auth tokens for publishing notifications

## Publishing notifications

For publishing notifications to ntfy (see also: <https://github.com/caronc/apprise/wiki/Notify_ntfy>):

```txt
ntfy://publisher:<password>@<domain>/<topic>
```

Alternatively you can also publish via email (see also <https://github.com/caronc/apprise/wiki/Notify_email>):

```txt
mailto://ntfy-<topic>+<token>@<domain>
```

Obviously replace `<domain>`, `<passowrd>`, `<token>` and `<topic>` with their respective values (remove enclosing `<>`).
