#!/bin/sh
set -euf

script_path="$(realpath "${0}")"
git_root_dir="$(git -C "$(dirname "${script_path}")" rev-parse --show-toplevel)"
app_dir_path="$(realpath "${1}")"

# shellcheck source=/dev/null
. "${git_root_dir}/docker-images/.shared/build-utils/parse-app-entry-utils.sh"

app_domain="$(get_app_domain "${app_dir_path}")"
app_ip="$(get_app_ip "${app_dir_path}")"

printf '%s %s\n' "${app_ip}" "${app_domain}"
