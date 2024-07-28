# HTTP Proxy

This is a simple HTTP/S proxy with Apache httpd server you put in front of your application.
Handle TLS certificates internally.

## Required ENV variables

- `HOST` - domain where this server will be running
- `UPSTREAM_URL` - upstream server url - the server we are proxying
- `HOMELAB_APP_TYPE` - what service type is upstream server
