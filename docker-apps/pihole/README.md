# Pi-hole

![diagram](../../docs/diagrams/out/apps/pihole.png)

- Docs: <https://docs.pi-hole.net>
- GitHub: <https://github.com/pi-hole/docker-pi-hole>
- DockerHub: <https://hub.docker.com/r/pihole/pihole>
- FTL Configuration: <https://docs.pi-hole.net/ftldns/configfile>

If proxy will cause issues, see: <https://www.reddit.com/r/pihole/comments/tttp7j/pihole_with_nginx_reverse_proxy_redirection_to>

The setup script is inspired by: <https://www.devwithimagination.com/2021/01/05/how-i-configure-pi-hole-without-the-ui>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Disable default adlists (only some instances)
- \[Prod\] Setup `uptime-kuma` monitoring:
    - IP (ping) monitor
    - TCP monitor for all open ports
    - HTTP/HTTPS monitor
    - DNS monitor
    - TBD: HTTPS JSON query monitor for basic API operation?
