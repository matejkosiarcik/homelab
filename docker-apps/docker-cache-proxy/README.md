# Docker cache proxy

- Documentation: <https://docs.docker.com/docker-hub/mirror>
- Relevant blogpost: <https://ranchergovernment.com/blog/mitigate-the-docker-dilemma-with-a-proxy-cache>
- Other considerations: <https://github.com/rpardini/docker-registry-proxy>

## Before initial installation

- \[All\] Create base secrets

## After initial installation

- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`
- \[Prod\] Setup `uptime-kuma` HTTP/HTTPS monitor
