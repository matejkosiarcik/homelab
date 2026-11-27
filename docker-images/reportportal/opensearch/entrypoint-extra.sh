# shellcheck disable=SC2148

saved_shell_options="${-}" # Preserve the calling entrypoint's shell options.
set -euf

# Copy everything from fake to real "local.d"
mkdir -p '/usr/share/opensearch/config'
cp -R '/homelab/original/usr/share/opensearch/config/.' '/usr/share/opensearch/config'

# Restore the calling entrypoint's shell options.
case "${saved_shell_options}" in *e*) ;; *) set +e ;; esac
case "${saved_shell_options}" in *u*) ;; *) set +u ;; esac
case "${saved_shell_options}" in *f*) ;; *) set +f ;; esac
unset saved_shell_options
