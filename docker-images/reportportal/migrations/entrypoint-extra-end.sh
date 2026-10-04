# shellcheck disable=SC2148

printf '%s - Finished migrations\n' "$(date '+%Y-%m-%d_%H-%M-%S')"

printf 'started\n' >'/homelab/tmpfs/status.txt'
exec sleep infinity
