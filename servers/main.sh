#!/usr/bin/env bash
set -eufo pipefail
# The reason to use `bash` instead of plain `sh` is that we require pipefail

print_help() {
    printf 'sh <script.sh> <command> [-h|--help] [-d|--dev|-p|--prod] [-f|--force] [-n|--dry-run]\n'
    printf '\n'
    printf 'Commands:\n'
    printf ' secrets - Create secrets for all docker apps\n'
    printf '\n'
    printf 'Arguments:\n'
    printf ' -d, --dev     - Dev mode\n'
    printf ' -f, --force   - Force\n'
    printf ' -h, --help    - Print help message\n'
    printf ' -n, --dry-run - Dry run\n'
    printf ' -p, --prod    - Production mode\n'
}

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments. COMMAND must be specified.\n' >&2
    print_help
    exit 1
fi

command="$1"
shift

if [ "$command" = '-h' ] || [ "$command" = '--help' ]; then
    print_help
    exit 0
fi

dry_run='0'
force='0'
mode='prod'
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d | --dev)
        mode='dev'
        shift
        ;;
    -f | --force)
        force='1'
        shift
        ;;
    -n | --dry-run)
        dry_run='1'
        shift
        ;;
    -p | --prod)
        mode='prod'
        shift
        ;;
    *)
        printf 'Unrecognized argument "%s"\n' "$1" >&2
        print_help
        exit 1
        ;;
    esac
done

create_all_secrets() {
    create_secrets_args="--$mode"
    if [ "$dry_run" = '1' ]; then
        create_secrets_args="$create_secrets_args --dry-run"
    fi
    if [ "$force" = '1' ]; then
        create_secrets_args="$create_secrets_args --force"
    fi

    find . -mindepth 1 -maxdepth 1 -type d -not -name '.*' | sort | while read -r server; do
        # shellcheck disable=SC2086
        cd "$server"
        task secrets -- $create_secrets_args
        cd -
    done
}

case "$command" in
secrets)
    create_all_secrets
    ;;
*)
    printf 'Unrecognized command "%s"\n' "$command" >&2
    print_help
    exit 1
    ;;
esac
