# Checklist for new Docker Apps

1. Add directory with `Dockerfile` in `docker-images/`
    - Add any custom config files
    - Check if the parent image has a built-in `HEALTHCHECK` -> If not, set it up.
2. Add directory with `compose.yml` files in `docker-apps/`
    - Add all usual scaffolding (_certificate-manager_, _http-proxy_)
    - Specific scaffolding (db-backup (litestream)?, bespoke prometheus-exporter?, other?)
3. Configure scripts
    - _http-proxy_ redirects
    - _secrets_ integration
4. Check if the app has a favicon and it displays in web browser
    - If not -> Add a custom one in `Dockerfile` (preferred) or in _http-proxy_ (fallback)
5. Generate secrets and save in _vaultwarden_
    - Main _admin_ password
    - Regular user passwords (_matej_, _monika_)
    - _http-proxy_ status password
    - Service specific passwords or API keys for: _gatus_, _homepage_, _prometheus_
    - Command: `bw generate -u -l -n --length 32` (note: add `-s` to include special characters)
6. Integration with other apps
    - Add DNS entry in _pihole_
    - Add link to _homepage_ dashboard
    - Add _gatus_ monitoring
    - Add _prometheus_ monitoring
7. Add tests
    - API:
        - Root
        - _prometheus_ endpoint
        - _health_ endpoint
    - UI:
        - Login
