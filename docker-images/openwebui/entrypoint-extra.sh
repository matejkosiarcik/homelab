# shellcheck disable=SC2148

saved_shell_options="${-}" # Preserve the calling entrypoint's shell options.
set -euf

# Copy files to real "/app/backend/open_webui/static"
mkdir -p '/app/backend/open_webui/static'
cp -R '/homelab/original/app/backend/open_webui/static/.' '/app/backend/open_webui/static'

# Restore the calling entrypoint's shell options.
case "${saved_shell_options}" in *e*) ;; *) set +e ;; esac
case "${saved_shell_options}" in *u*) ;; *) set +u ;; esac
case "${saved_shell_options}" in *f*) ;; *) set +f ;; esac
unset saved_shell_options
