# Smtp4Dev

For general `smtp4dev` docs see [/docker-images/smtp4dev/README.md](../../../../docker-images/external/smtp4dev/README.md)

## Before installation

Before installation prepare following files:

- `/private/status.htpasswd` - Password file (basic-auth) for apache to protect server-status endpoint
- `/private/certs` -  Directory with TLS certificates (crt, csr, key) to use with HTTPS
