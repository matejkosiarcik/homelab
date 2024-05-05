# Smtp4Dev

> Local smtp server for development

- GitHub: <https://github.com/rnwood/smtp4dev>
- DockerHub: <https://hub.docker.com/r/rnwood/smtp4dev>
- Docs guide: <https://mailosaur.com/blog/a-guide-to-smtp4dev>
- Docs installation <https://github.com/rnwood/smtp4dev/wiki/Installation>
- Docs configuration: <https://github.com/rnwood/smtp4dev/wiki/Configuration>

## Before installation

Before installation prepare following files:

- `/private/status.htpasswd` - Password file (basic-auth) for apache to protect server-status endpoint
- `/private/certs` -  Directory with TLS certificates (crt, csr, key) to use with HTTPS
