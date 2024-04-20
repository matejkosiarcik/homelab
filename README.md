# Personal Homelab

> My personal homelab config

This is a source-open repository, so external Pull Requests aren't expected, but not completely banned.

Below is a general format for this repository:

- `/guides/` - General guides for things that are done once in a while, such as installing new machine
- `/machines/` - Everything that should run on given machines
  - `/[machine...]/` - All config specific for individual machine
    - `/install.sh` - Install script
    - `/startup.sh` - Startup script (should be run via cron at `@reboot`)
    - `/[service...]/` - All config for individual service
