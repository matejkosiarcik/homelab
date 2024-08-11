# Healthchecks.io

For healthchecks.io docs see [/docker-images/healthchecks/README.md](../../../../docker-images/external/healthchecks/README.md)

## Installation

Before installation prepare following files:

- `/private/app.env` - Contains following variables:
    - `SECRET_KEY` - Secret key for encryption, is not used anywhere else
    - `DB_PASSWORD` - Password for postgres
- `/private/database-password.txt` - Password for postgres database (forbids trailing newline)
- `/private/database-backup.env` - Contains following variables:
    - `PGPASSWORD` - Password for postgres
    - `HEALTHCHECK_URL` - Full URL (protocol, domain/host, ping uuid) to Healthchecks ping check
