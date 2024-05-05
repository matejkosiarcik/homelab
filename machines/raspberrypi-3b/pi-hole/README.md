# Pi-hole

- Docs: <https://docs.pi-hole.net>
- GitHub: <https://github.com/pi-hole/docker-pi-hole>
- DockerHub: <https://hub.docker.com/r/pihole/pihole>
- FTL Configuration: <https://docs.pi-hole.net/ftldns/configfile>

If proxy will cause issues see <https://www.reddit.com/r/pihole/comments/tttp7j/pihole_with_nginx_reverse_proxy_redirection_to>

## Before installation

Before installation prepare following files:

- `/private/webpassword.txt` - Password for UI login (permits trailing newline)
- `/private/app-backup.env` - Contains following environment variables:
    - `PASSWORD` - UI admin account password
    - `HEALTHCHECK_URL` - Full URL (protocol, domain/host, ping uuid) to Healthchecks ping check
