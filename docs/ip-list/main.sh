#!/bin/sh
set -euf

script_path="$(realpath "${0}")"
script_dir="$(dirname "${script_path}")"
git_root_dir="$(git -C "$(dirname "${script_path}")" rev-parse --show-toplevel)"
readme_filepath="${script_dir}/README.md"
app_entry_parser_filepath="${script_dir}/parse-app-entry.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT HUP INT TERM

app_entries_filepath="${tmpdir}/app-entries.txt"
table_filepath="${tmpdir}/table.md"
updated_readme_filepath="${tmpdir}/README.md"

find "${git_root_dir}/servers" -path "${git_root_dir}/servers/*/docker-apps/*" -mindepth 3 -maxdepth 3 -type d -not -name '.*' -print0 |
    xargs -0 -I% sh "${app_entry_parser_filepath}" % | sort --version-sort >"${app_entries_filepath}"

max_lengths="$(awk '
    length($1) > max_ip_length { max_ip_length = length($1) }
    length($2) > max_domain_length { max_domain_length = length($2) }
    END { printf "%s %s", max_ip_length, max_domain_length }
' "${app_entries_filepath}")"
max_ip_length="${max_lengths% *}"
max_domain_length="${max_lengths#* }"
ip_header='IP address'
domain_header='Domain'
if [ "${#ip_header}" -gt "${max_ip_length}" ]; then
    max_ip_length="${#ip_header}"
fi
if [ "${#domain_header}" -gt "${max_domain_length}" ]; then
    max_domain_length="${#domain_header}"
fi
ip_column_length="$((max_ip_length + 2))"
domain_column_length="$((max_domain_length + 2))"
ip_separator="$(printf '%*s' "$((ip_column_length + 2))" '' | tr ' ' '-')"
domain_separator="$(printf '%*s' "$((domain_column_length + 2))" '' | tr ' ' '-')"

{
    printf '\n'
    printf '| %-*s | %-*s |\n' "${ip_column_length}" "${ip_header}" "${domain_column_length}" "${domain_header}"
    printf '|%s|%s|\n' "${ip_separator}" "${domain_separator}"
    while IFS=' ' read -r app_ip app_domain; do
        ip_padding="$((max_ip_length - ${#app_ip}))"
        domain_padding="$((max_domain_length - ${#app_domain}))"
        # shellcheck disable=SC2016
        printf '| `%s`%*s | `%s`%*s |\n' "${app_ip}" "${ip_padding}" '' "${app_domain}" "${domain_padding}" ''
    done <"${app_entries_filepath}"
    printf '\n'
} >"${table_filepath}"

awk -v table_filepath="${table_filepath}" '
    $0 == "<!-- IP start -->" {
        if (start_count != 0 || in_ip_section) {
            printf "Invalid IP section markers in README.md\\n" > "/dev/stderr"
            exit 1
        }

        start_count++
        in_ip_section = 1
        print
        while ((getline line < table_filepath) > 0) {
            print line
        }
        close(table_filepath)
        next
    }
    $0 == "<!-- IP end -->" {
        if (!in_ip_section || end_count != 0) {
            printf "Invalid IP section markers in README.md\\n" > "/dev/stderr"
            exit 1
        }

        end_count++
        in_ip_section = 0
        print
        next
    }
    !in_ip_section {
        print
    }
    END {
        if (start_count != 1 || end_count != 1 || in_ip_section) {
            printf "Invalid IP section markers in README.md\\n" > "/dev/stderr"
            exit 1
        }
    }
' "${readme_filepath}" >"${updated_readme_filepath}"

mv "${updated_readme_filepath}" "${readme_filepath}"
chmod 0644 "${readme_filepath}"
