# shellcheck disable=SC2148

saved_shell_options="${-}" # Preserve the calling entrypoint's shell options.
set -euf

# Copy files to real "/app/.next/server/pages"
mkdir -p '/app/.next/server/pages'
cp -R '/homelab/original/app/.next/server/pages/.' '/app/.next/server/pages'

# Copy files to real "/app/config"
mkdir -p '/app/config'
cp -R '/homelab/config/.' '/app/config'

# Restore the calling entrypoint's shell options.
case "${saved_shell_options}" in *e*) ;; *) set +e ;; esac
case "${saved_shell_options}" in *u*) ;; *) set +u ;; esac
case "${saved_shell_options}" in *f*) ;; *) set +f ;; esac
unset saved_shell_options
