# Unifi network application

For general `unifi-controller` docs see [/docker-images/external/unifi-controller/README.md](../../../../docker-images/external/unifi-controller/README.md)

For general `mongodb` docs see [/docker-images/external/mongodb/README.md](../../../../docker-images/database/mongodb/README.md)

## Installation

Before installation prepare following files:

- `/private/database-password.txt` - Password for MongoDB database (forbids trailing newline)
- `/private/webui-backup.env` - Contains following environment variables:
    - `USERNAME` - UI admin account username
    - `PASSWORD` - UI admin account password
    - `HEALTHCHECK_URL` - Full URL (protocol, domain/host, ping uuid) to Healthchecks ping check
