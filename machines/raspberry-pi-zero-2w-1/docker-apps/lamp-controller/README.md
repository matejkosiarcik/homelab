# Lamp controller

For more docs see [/docker-images/lamps/network-server/README.md](../../../docker-images/custom/lamp-network-server/README.md) [/docker-images/lamps/hardware-controller/README.md](../../../docker-images/custom/lamp-hardware-controller/README.md)

## Before installation

Before installation prepare following files:

- `/private/status.htpasswd` - Password file (basic-auth) for apache to protect server-status endpoint
- `/private/certs` -  Directory with TLS certificates (crt, csr, key) to use with HTTPS
