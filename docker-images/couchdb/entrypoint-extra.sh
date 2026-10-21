# shellcheck disable=SC2148

# Define portable datetime format
date_supports_milliseconds="$(date +'%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

# Copy everything from fake to real "local.d"
mkdir -p '/opt/couchdb/etc/local.d'
cp -R '/homelab/original/opt/couchdb/etc/local.d/.' '/opt/couchdb/etc/local.d'

HMAC_KEY_BASE64="$(printf '%s' "${HMAC_KEY}" | base64)"
export HMAC_KEY_BASE64

tmpdir="$(mktemp -d)"
config_file='/opt/couchdb/etc/local.d/jwt.ini'
config_file_tmp="${tmpdir}/jwt.ini"

envsubst -no-digit -no-unset -no-empty -i "${config_file}" -o "${config_file_tmp}" || {
    printf '%s [ERROR]: An error happened during processing of %s to %s\n' "$(date "${datetime_format}")" "${config_file}" "${config_file_tmp}" >&2
    exit 1
}

mv "${config_file_tmp}" "${config_file}"
rm -rf "${tmpdir}"
