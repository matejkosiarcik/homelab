# Checklist for new Docker Apps

1. Add directory with `Dockerfile` in `docker-images/`
    - Add any custom config files
    - Check if the parent image has a built-in `HEALTHCHECK` -> If not, set it up.
2. Add directory with `compose.yml` files in `docker-apps/`
    - Add all usual scaffolding (_certificator_, _apache_)
    - Specific scaffolding (db-backup (litestream)?, builtin/3rd-party/custom prometheus-exporter?, other?)
3. Configure scripts
    - _apache_ redirects
    - _secrets_ integration
4. Check if the app has a favicon and it displays in web browser
    - If not -> Add a custom one in `Dockerfile` (preferred) or in _apache_ (fallback)
5. Generate secrets and save in _vaultwarden_
    - Main _admin_ password
    - Regular user passwords (_matej_, _monika_)
    - _apache_ proxy-status and proxy-prometheus passwords
    - Service specific passwords or API keys (_gatus_, _homepage_, _ntfy_, _prometheus_, ...)
    - Command: `bw generate -u -l -n --length 32` (note: add `-s` to include special characters)
6. Integration with other apps
    - Add DNS entry in _pihole_
    - Add _vaultwarden_ secrets
    - Setup _gatus_ monitoring (don't forget secrets if monitoring protected endpoints)
    - Setup _prometheus_ monitoring  (don't forget secrets)
    - Setup _healthchecks_ monitoring (certificator, ...)
    - Add link in _homepage_ dashboard (don't forget secrets if using plugins)
    - Add _tests_
7. Add tests for intranet apps:
    - API:
        - Root
        - _prometheus_ endpoint
        - _health_ endpoint
    - UI:
        - Login
