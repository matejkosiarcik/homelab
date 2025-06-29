# Personal Homelab

> My personal homelab

This is my personal homelab config.
Given the nature of this project, as it applies only to me, third-party pull requests are not expected.

TL;DR:

![diagram](./docs/diagrams/out/homelab.png)

Below is a general structure for this repository:

- `/ansible/` - Ansible playbooks for easy maintenance for multiple servers
- `/docs/` - General documentation and installation guides
- `/docker-images/` - Contains Dockerfiles for all individual docker images
- `/docker-compose/` - Reusable config for entire individual docker-apps
- `/other-apps/` - Non-Docker apps (eg. for microcontrollers)
- `/servers/` - Setup for individual physical servers

Common env variables:

- `HOMELAB_APP_TYPE` - Main app name (eg. _pihole_)
- `HOMELAB_ENV` - Current env type, either _dev_ or _prod_
- `HOMELAB_APP_EXTERNAL_DOMAIN` - Local domain alias (eg. _pihole.matejhome.com_)
- `HOMELAB_HEALTHCHECK_URL` - Healthcheck URL to report CRON job status
- `HOMELAB_CONTAINER_VARIANT` - In case multiple containers of the same image are used in a single app, this differentiates between them
- Credentials:
    - `HOMELAB_APP_USERNAME` - Username (or email) for app login
    - `HOMELAB_APP_PASSWORD` - Password for app login
