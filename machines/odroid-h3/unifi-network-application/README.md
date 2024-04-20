# Unifi network application

## App

- GitHub: <https://github.com/linuxserver/docker-unifi-network-application>
- DockerHub: <https://hub.docker.com/r/linuxserver/unifi-network-application>
- Open Ports overview: <https://help.ui.com/hc/en-us/articles/218506997-UniFi-Network-Required-Ports-Reference>

### Note for Healtcheck

This is good `/status`:

```json
{
  "meta": {
    "rc": "ok",
    "up": true,
    "server_version": "[REDACTED]",
    "uuid": "[REDACTED]"
  },
  "data": []
}
```

This is bad `/status`:

```json
{
  "meta": {
    "rc": "ok",
    "server_version": "[REDACTED]",
    "server_running": false,
    "db_migrating": false,
    "up": false,
    "app_context_status": "[REDACTED]",
    "app_context_message": "[REDACTED]"
  },
  "data": []
}
```

## MongoDB

DockerHub: <https://hub.docker.com/_/mongo>

## Installation

Before installation prepare following files:

- `/private/mongodb-password.txt` - Password for MongoDB database (forbids trailing newline)
