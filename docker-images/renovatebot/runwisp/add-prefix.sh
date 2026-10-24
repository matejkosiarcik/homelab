#!/bin/sh
set -euf

tmpdir="$(mktemp -d)"
text_files_list="${tmpdir}/files.txt"

# Get a list of valid files to change
find '.' -not -path '*.git/*' -type f -not \( -iname '*.png' -or -iname 'go.mod' -or -iname 'go.sum' -or -iname '*.lock' -or -iname '*.md' \) | while read -r file; do
    if file "${file}" | grep -q 'text' >/dev/null 2>&1; then
        printf '%s\n' "${file}" >>"${text_files_list}"
    fi
done

# Change svelte config base-path
if [ ! -f './apps/ui/svelte.config.js' ]; then
    printf 'Svelte config not found at "./apps/ui/svelte.config.js"\n' >&2
    exit 1
fi
svelte_config_shasum_before="$(shasum './apps/ui/svelte.config.js')"
cat './apps/ui/svelte.config.js' | sed 's~base: "",~base: "/runwisp",~' | sponge './apps/ui/svelte.config.js'
svelte_config_shasum_after="$(shasum './apps/ui/svelte.config.js')"
if [ "${svelte_config_shasum_before}" = "${svelte_config_shasum_after}" ]; then
    printf 'Svelte config not changed, could not apply new basepath\n' >&2
    exit 1
fi

# Add prefix to paths: "/api", "/health", "/healthz", "/metrics"
cat "${text_files_list}" | while read -r file; do
    extension="$(printf '%s' "${file}" | sed -E 's~^.*\.~~')"
    cat "${file}" | sed -E 's~([^[:alnum:]])/(api|healthz?|metrics)([^[:alnum:]])~\1/runwisp/\2\3~g' | sponge "${file}"
done
