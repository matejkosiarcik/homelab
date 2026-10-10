# Matej's personal homelab

This is my personal homelab config.
Given the nature of this project, as it applies only to me, third-party pull requests are not expected.

General structure for this repository:

- `/ansible/` - Ansible playbooks for easy maintenance for multiple servers
- `/docs/` - General documentation and installation guides
- `/docker-images/` - Contains Dockerfiles for all individual Docker images
- `/docker-compose/` - Reusable config for entire individual docker-apps. Each compose stack references one or more Dockerfiles from `docker-images`
- `/other-apps/` - Non-Docker apps (eg. for microcontrollers)
- `/servers/` - Setup for individual physical servers
    - `/servers/<server>` - Files related to a single server
        - `/servers/<server>/docker-apps` - Docker apps that run on this server. Each app references exactly one `docker-compose` stack

> What does your homelab do?

TL;DR:

![diagram](./docs/diagrams/out/homelab.png)
