# Docker cache proxy

- Documentation: <https://docs.docker.com/docker-hub/mirror>
- DockerHub: <https://hub.docker.com/_/registry>

Generic resources:

- Tutorial for using multiple mirrors: <https://blog.alexellis.io/how-to-configure-multiple-docker-registry-mirrors>
- Relevant blogpost: <https://ranchergovernment.com/blog/mitigate-the-docker-dilemma-with-a-proxy-cache>
- <!-- textlint-disable -->
  Docker proxy general API: <https://distribution.github.io/distribution/spec/api>
  <!-- textlint-enable -->

---

Other considerations:

- Official Docker registry
    - I also considered the official docker-registry image, but it has a couple downsides.
      Namely 1 instance can only proxy 1 upstream, so you need N instances for N upstreams (dockerhub, ghcr.io, ...) and lacks built-in admin interface, which also needs N instances
- Docker registry proxy:
    - This one looks unmaintained
    - GitHub: <https://github.com/rpardini/docker-registry-proxy>

I also tried _Sonatype Nexus3_:

- GitHub: <https://github.com/sonatype/docker-nexus3>
- DockerHub: <https://hub.docker.com/r/sonatype/nexus3>
- Setup Tutorial: <https://mtijhof.wordpress.com/2018/07/23/using-nexus-oss-as-a-proxy-cache-for-docker-images>
- Official docs: <https://help.sonatype.com/en/sonatype-nexus-repository.html>

It has a couple pros and cons:

- Pros:
    - Can proxy docker, and other types of content
    - Can add/remove proxies and artifactories in UI on demand
    - Supports automatic cleanup schedules
    - Can remove artifacts (images, layers) in the admin UI
- Cons:
    - Clunky initial setup (must setup admin credentials interactively)
    - Must configure proxies post-install interactively, no configuration as code
    - Consumes a lot of CPU and RAM (when doing nothing consumes 20% CPU and 200MB of RAM)

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`
- \[Prod\] Add healthchecks monitor for `admin-setup` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Setup `uptime-kuma` HTTP/HTTPS monitor
- \[Prod\] Setup `uptime-kuma` HTTPS JSON query monitor for basic API operation
- \[Prod\] Configure docker-proxy repositories and docker-group with external access according to _Setup Tutorial_ above
