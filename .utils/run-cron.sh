#!/bin/sh
set -euf

print_help() {
    printf 'sh run-cron.sh [-h] -c <cmd>\n'
    printf '\n'
    printf 'Arguments:\n'
    printf ' -h  - Print usage\n'
    printf ' -c  - Command to run\n'
}

command=''
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h)
            print_help
            exit 0
            ;;
        -c)
            shift
            command="$1"
            shift
            ;;
        *)
            print_help
            exit 1
            ;;
    esac
done

if [ "$command" = '' ]; then
    printf 'Command unset\n' >&2
    exit 1
fi

healthchecks_base_url='http://app:8080'
healthchecks_uuid='3dec9327-0ecf-4e37-984f-6027ed920a38'

url="$healthchecks_base_url/ping/$healthchecks_uuid"
start_url="$url/start"
end_success_url="$url"
end_fail_url="$url/fail"

curl --request POST --retry 3 --max-time 10 --fail --silent --show-error "$start_url"
if eval "$command"; then
    curl --request POST --retry 3 --max-time 10 --fail --silent --show-error "$end_success_url"
else
    curl --request POST --retry 3 --max-time 10 --fail --silent --show-error "$end_fail_url"
fi
