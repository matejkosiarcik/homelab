#!/bin/sh
set -euf

# Wait for certificates to exist before starting
timeout 30s sh <<EOF
while [ ! -e '/homelab/certs' ]; do
    sleep 1
done
while [ ! "$(find '/homelab/certs' -type f | grep . -c)" -gt 0 ]; do
    sleep 1
done
EOF

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'certificate\.crt' '/homelab/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates\n" && apachectl -k restart' - &

printf '\n' >>/etc/apache2/envvars

# Set HOMELAB_ENV
if [ "${HOMELAB_ENV-x}" = 'x' ]; then
    printf 'HOMELAB_ENV unset\n' >&2
    exit 1
fi
export HOMELAB_ENV
printf "export HOMELAB_ENV='%s'\n" "$HOMELAB_ENV" >>/etc/apache2/envvars

# Set HOMELAB_APP_TYPE
if [ "${HOMELAB_APP_TYPE-x}" = 'x' ]; then
    printf 'HOMELAB_APP_TYPE unset\n' >&2
    exit 1
fi
export HOMELAB_APP_TYPE
printf "export HOMELAB_APP_TYPE='%s'\n" "$HOMELAB_APP_TYPE" >>/etc/apache2/envvars

# Set REDIRECT_HTTPS_PORT
if [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'raw' ]; then
    REDIRECT_HTTPS_PORT='8443'
else
    REDIRECT_HTTPS_PORT='443'
fi
export REDIRECT_HTTPS_PORT
printf "export REDIRECT_HTTPS_PORT='%s'\n" "$REDIRECT_HTTPS_PORT" >>/etc/apache2/envvars

# Start apache
apachectl -D FOREGROUND
