# Lamp controller

For more docs see [/components/lamps/network-server/README.md](../../../components/lamps/network-server/README.md) [/components/lamps/hardware-controller/README.md](../../../components/lamps/hardware-controller/README.md)

## Before installation

Before installation prepare following files:

- `/private/status.htpasswd` - Password file (basic-auth) for apache to protect server-status endpoint
- `/private/certs` -  Directory with TLS certificates (crt, csr, key) to use with HTTPS
