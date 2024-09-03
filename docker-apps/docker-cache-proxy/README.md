# Docker cache proxy

This app is based on _Sonatype Nexus3_.

- GitHub: <https://github.com/sonatype/docker-nexus3>
- DockerHub: <https://hub.docker.com/r/sonatype/nexus3/>
- Setup Tutorial: <https://mtijhof.wordpress.com/2018/07/23/using-nexus-oss-as-a-proxy-cache-for-docker-images>

Generic resources:

- Tutorial for using multiple mirrors: <https://blog.alexellis.io/how-to-configure-multiple-docker-registry-mirrors>
- Relevant blogpost: <https://ranchergovernment.com/blog/mitigate-the-docker-dilemma-with-a-proxy-cache>

I also considered the official docker-registry image, but it has a couple downsides.
Namely 1 instance can only proxy 1 upstream, so you need N instances for N upstreams (dockerhub, ghcr.io, ...) and lacks builtin admin interface, which also needs N instances.

- Documentation: <https://docs.docker.com/docker-hub/mirror>
- DockerHub: <https://hub.docker.com/_/registry>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`
- \[Prod\] Add healthchecks monitor for `admin-setup` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Configure docker-proxy repositories and docker-group with external access according to _Setup Tutorial_ above
- \[Prod\] Setup `uptime-kuma` HTTP/HTTPS monitor
- \[Prod\] Setup `uptime-kuma` HTTPS JSON query monitor for basic API operation
