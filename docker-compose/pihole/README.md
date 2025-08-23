# Pi-hole

![diagram](../../docs/diagrams/out/apps/pihole.png)

## Docs

PiHole:

- GitHub: <https://github.com/pi-hole/docker-pi-hole>
- DockerHub: <https://hub.docker.com/r/pihole/pihole>
- Docs: <https://docs.pi-hole.net>
- Docs - Docker: <https://docs.pi-hole.net/docker>
- Docs - FTL Configuration: <https://docs.pi-hole.net/ftldns/configfile>

Prometheus exporter:

- GitHub: <https://github.com/eko/pihole-exporter>
- DockerHub: <https://hub.docker.com/r/ekofr/pihole-exporter>

Other notes:

- If proxy will cause issues, see: <https://www.reddit.com/r/pihole/comments/tttp7j/pihole_with_nginx_reverse_proxy_redirection_to>
- The setup script is inspired by: <https://www.devwithimagination.com/2021/01/05/how-i-configure-pi-hole-without-the-ui>

## Before initial installation

- Follow general [guide](../../docs/Checklist%20for%20new%20docker-apps.md)

## After initial installation

- Disable destructive API actions
