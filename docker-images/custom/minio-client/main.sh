#!/bin/sh
set -euf

script_dir="$(dirname "$0")"

if [ -e '/.dockerenv' ]; then
    minio_url='http://minio:9000'
else
    minio_url='https://localhost:8443'
fi
if [ -n "${MINIO_URL+x}" ]; then
    minio_url="$MINIO_URL"
fi

timeout 30s sh <<EOF
while ! curl --fail --insecure "$minio_url/minio/health/live"; do
    sleep 1
done
EOF
sleep 1

MC_QUIET='1'
export MC_QUIET
MC_INSECURE='1'
export MC_INSECURE

mc alias set minio "$minio_url" "$HOMELAB_ADMIN_USERNAME" "$HOMELAB_ADMIN_PASSWORD"
mc ping minio --exit

if ! mc admin user list minio | grep "$HOMELAB_USER_USERNAME" >/dev/null; then
    mc admin user add minio "$HOMELAB_USER_USERNAME" "$HOMELAB_USER_PASSWORD"
    mc admin policy attach minio readwrite --user "$HOMELAB_USER_USERNAME"
fi

# Create new buckets
while read -r bucket; do
    if ! (mc ls minio | grep "$bucket/" >/dev/null); then
        mc mb "minio/$bucket"
    fi
done <"$script_dir/plain-buckets.txt"
while read -r bucket; do
    if ! (mc ls minio | grep "$bucket/" >/dev/null); then
        mc mb --with-versioning "minio/$bucket"
    fi
done <"$script_dir/versioned-buckets.txt"
