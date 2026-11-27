# shellcheck disable=SC2148

saved_shell_options="${-}" # Preserve the calling entrypoint's shell options.
set -euf

DATABASE_URL="postgresql://postgres:${DATABASE_PASSWORD}@postgres/database"
export DATABASE_URL

# Restore the calling entrypoint's shell options.
case "${saved_shell_options}" in *e*) ;; *) set +e ;; esac
case "${saved_shell_options}" in *u*) ;; *) set +u ;; esac
case "${saved_shell_options}" in *f*) ;; *) set +f ;; esac
unset saved_shell_options
