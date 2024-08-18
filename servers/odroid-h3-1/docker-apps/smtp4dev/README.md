# Smtp4Dev

For general `smtp4dev` docs see [/docker-apps/smtp4dev/README.md](../../../../docker-apps/smtp4dev/README.md)

## Before installation

Before installation prepare following files:

- `/private/http-proxy-status.htpasswd` - Password file (basic-auth) for apache to protect server-status endpoint
- `/private/certs` -  Directory with TLS certificates (crt, csr, key) to use with HTTPS
