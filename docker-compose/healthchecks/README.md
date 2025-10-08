# Healthchecks.io

![diagram](../../docs/diagrams/out/apps/healthchecks.png)

## Docs

- GitHub: <https://github.com/healthchecks/healthchecks>
- DockerHub: <https://hub.docker.com/r/healthchecks/healthchecks>
- Docs - General: <https://healthchecks.io/docs/self_hosted_docker>
- Docs - Server configuration: <https://healthchecks.io/docs/self_hosted_configuration>
- Docs - Running in Docker: <https://healthchecks.io/docs/self_hosted_docker>

## Before initial installation

- Follow general [guide](../../docs/Checklist%20for%20new%20docker-apps.md)

## After initial installation

- Create `matej@matejhome.com` and `test@matejhome.com` accounts
    - Turn on password authentication
- Configure notifications: ntfy & gotify
    - `https://ntfy.matejhome.com` + topic + access-token
    - `https://gotify.matejhome.com` + token
- Generate api-key / api-key (readonly) / ping-key and save it in Vaultwarden
- Run script to create all healthchecks
