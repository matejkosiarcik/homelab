# Pi-hole

For Pi-Hole docs see [/components/pihole/README.md](../../../components/pihole/README.md)

## Before installation

Before installation prepare following files:

- `/private/webpassword.txt` - Password for UI login (permits trailing newline)
- `/private/webui-backup.env` - Contains following environment variables:
    - `PASSWORD` - UI admin account password
    - `HEALTHCHECK_URL` - Full URL (protocol, domain/host, ping uuid) to Healthchecks ping check
- `/private/status.htpasswd` - Password file (basic-auth) for apache to protect server-status endpoint
- `/private/certs` -  Directory with TLS certificates (crt, csr, key) to use with HTTPS
