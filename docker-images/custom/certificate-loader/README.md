# HTTP Proxy

This is a certificate-loader that handles TLS certificates for individual apps.
In dev mode it creates self-signed certificates.
In prod mode it downloads real certificates from a trusted source - Not implemented yet.
In both cases keeps track of certificate validity on schedule and recreates them if needed.
