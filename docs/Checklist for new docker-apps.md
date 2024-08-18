# Checklist for new docker-apps

1. Add directory with `Dockerfile` file in `docker-images/`
  - Check if the parent image has a builtin healthcheck -> If not add it.
2. Add directory with `docker-compose.yml` files in `docker-apps/`
  - Add all usual scaffolding (certificate-manager, http-proxy, socket-proxy, web-backup / db-backup)
3. Add directory in a specific `servers/<server>/docker-apps/` that will use the app
4. Check if the main image has a favicon in browser -> If not add a custom one
5. Add this app to _homer_ dashboard
