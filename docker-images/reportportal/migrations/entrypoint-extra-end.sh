# shellcheck disable=SC2148

printf '%s - Finished migrations\n' "$(date '+%Y-%m-%d_%H-%M-%S')"

printf 'started\n' >/homelab/tmpfs/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
