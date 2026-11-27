# shellcheck disable=SC2148

saved_shell_options="${-}" # Preserve the calling entrypoint's shell options.
set -euf

# Copy everything from fake to real "/etc/nginx/conf.d"
mkdir -p '/etc/nginx/conf.d'
cp -R '/homelab/original/etc/nginx/conf.d/.' '/etc/nginx/conf.d'

# Restore the calling entrypoint's shell options.
case "${saved_shell_options}" in *e*) ;; *) set +e ;; esac
case "${saved_shell_options}" in *u*) ;; *) set +u ;; esac
case "${saved_shell_options}" in *f*) ;; *) set +f ;; esac
unset saved_shell_options
