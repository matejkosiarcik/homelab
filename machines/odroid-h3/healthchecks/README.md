# Healthchecks.io

## App

- Github: <https://github.com/healthchecks/healthchecks>
- DockerHub: <https://hub.docker.com/r/healthchecks/healthchecks>
- Docs - General: <https://healthchecks.io/docs/self_hosted_docker>
- Docs - Server configuration: <https://healthchecks.io/docs/self_hosted_configuration>

## Postgres

- DockerHub: <https://hub.docker.com/_/postgres>

## Installation

Before installation prepare following files:

- `/private/app.env` - Contains following variables:
    - `SECRET_KEY` - Secret key for encryption, is not used anywhere else
    - `DB_PASSWORD` - Password for postgres
- `/private/database-password.txt` - Password for postgres database (forbids trailing newline)
- `/private/database-backup.env` - Contains following variables:
    - `PGPASSWORD` - Password for postgres
    - `HEALTHCHECK_URL` - Full URL (protocol, domain/host, ping uuid) to Healthchecks ping check
