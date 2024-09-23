# Jellyfin

![diagram](../../docs/diagrams/out/apps/jellyfin.png)

- DockerHub: <https://hub.docker.com/r/linuxserver/jellyfin>
- Linuxserver docs: <https://docs.linuxserver.io/images/docker-jellyfin>
- GitHub: <https://github.com/linuxserver/docker-jellyfin>
- Jellyfin docs: <https://jellyfin.org/docs/general/quick-start>

## Before initial installation

- \[All\] Create base secrets
- \[Prod\] Add healthchecks monitor for `certificate-manager` and configure `HOMELAB_HEALTHCHECK_URL`

## After initial installation

- \[Prod\] Setup `uptime-kuma` HTTP/HTTPS monitor
- \[Prod\] Complete initial setup wizard
    - Create "admin" user
    - Disable remote connections
- \[Prod\] Customize settings (eg. ) (location: Settings -> Administration -> General)
    - Disable "Quick Connect"
    - Verify "Server Name"
- \[Prod\] Connect to Tvheadend
    - Install Tvheadend plugin (location: Settings -> Administration -> Plugins -> Catalog)
    - Restart Jellyfin
    - Configure Tvheadend plugin details (location: Settings -> Administration -> Plugins -> My Plugins -> Tvheadend)
        - Tvheadend address, credentials
        - Enable "Hide Tvheadend Recordings channel"
    - Refresh Guide Data (location: Settings -> Administration -> Live TV)
- \[Prod\] Create extra users (matej, monika)

NOTE: Some clients may require unchecking "Prefer fMP4-HLS Media Container" for each user/client,
because it is stored on the client-side in browser `localStorage` (location: Settings -> Playback).
