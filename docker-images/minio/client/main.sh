#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message || [ -n "${log_message}" ]; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

script_dir="$(dirname "${0}")"

if [ -n "${MINIO_URL+x}" ]; then
    minio_url="${MINIO_URL}"
elif [ -e '/.dockerenv' ]; then
    minio_url='http://app:9000'
else
    minio_url='https://localhost:8443'
fi

# Wait for minio to start
timeout 30s sh <<EOF
log() {
    # \$1 - log level
    # \$2+ - message

    log_level="\${1}"
    shift
    log_timestamp="\$(date "${datetime_format}")"
    printf '%s\n' "\${*}" | while IFS= read -r log_message || [ -n "\${log_message}" ]; do
        printf '%s [%s]: %s\n' "\${log_timestamp}" "\${log_level}" "\${log_message}"
    done >&2
}

log INFO 'Waiting for minio deployment'
while ! curl --fail "${minio_url}/minio/health/live"; do
    sleep 1
done
log INFO 'MinIO deployment available'
sleep 1
EOF

MC_QUIET='1'
export MC_QUIET
MC_INSECURE='1'
export MC_INSECURE

mc alias set minio "${minio_url}" 'matej' "${MINIO_MATEJ_PASSWORD}"
mc ping minio --exit

mc admin user add minio 'homelab-writer' "${MINIO_HOMELAB_WRITER_PASSWORD}"
mc admin policy attach minio readwrite --user 'homelab-writer'

mc admin user add minio 'homelab-viewer' "${MINIO_HOMELAB_VIEWER_PASSWORD}"
mc admin policy attach minio readonly --user 'homelab-viewer'

mc admin user add minio 'homelab-test' "${MINIO_HOMELAB_TEST_PASSWORD}"
mc admin policy attach minio readonly --user 'homelab-test'

# Create new buckets
while read -r bucket; do
    if ! (mc ls minio | grep "${bucket}/" >'/dev/null'); then
        mc mb "minio/${bucket}"
    fi
done <"${script_dir}/plain-buckets.txt"
while read -r bucket; do
    if ! (mc ls minio | grep "${bucket}/" >'/dev/null'); then
        mc mb --with-versioning "minio/${bucket}"
    fi
done <"${script_dir}/versioned-buckets.txt"
