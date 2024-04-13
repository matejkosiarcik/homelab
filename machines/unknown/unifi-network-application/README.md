# Unifi network application

- GitHub: https://github.com/linuxserver/docker-unifi-network-application
- DockerHub: https://hub.docker.com/r/linuxserver/unifi-network-application

## Note for Healtcheck

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

DockerHub: https://hub.docker.com/_/mongo
