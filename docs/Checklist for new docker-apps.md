# Checklist for new docker-apps

1. Add directory with `Dockerfile` file in `docker-images/`
    - Check if the parent image has a built-in healthcheck -> If not add it.
2. Add directory with `docker-compose.yml` files in `docker-apps/`
    - Add all usual scaffolding (certificate-manager, http-proxy, transport-proxy)
    - Specific scaffolding (litestream?, custom-setup?, custom-backup?)
3. Add directory in a specific `servers/<server>/docker-apps/` that will use the app
4. Check if the main image has a favicon and it displays in web browser
    - If not -> Add a custom one in the service image (preferred) or in apache proxy (fallback)
5. Add this app to _homepage_ dashboard
