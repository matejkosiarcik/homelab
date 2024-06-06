# Unifi network application

For general `unifi-network-application` docs see [/components/unifi-network-application/README.md](../../../components/unifi-network-application/README.md)

For general `mongodb` docs see [/components/mongodb/README.md](../../../components/mongodb/README.md)

## Installation

Before installation prepare following files:

- `/private/database-password.txt` - Password for MongoDB database (forbids trailing newline)
- `/private/webui-backup.env` - Contains following environment variables:
    - `USERNAME` - UI admin account username
    - `PASSWORD` - UI admin account password
    - `HEALTHCHECK_URL` - Full URL (protocol, domain/host, ping uuid) to Healthchecks ping check
