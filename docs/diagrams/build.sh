#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

mode=''
only_pattern=''
if [ "${HOMELAB_ENV-}" != '' ]; then
    mode="${HOMELAB_ENV}"
fi
while [ "${#}" -gt 0 ]; do
    case "${1}" in
    -d | --dev)
        mode='dev'
        shift
        ;;
    -p | --prod)
        mode='prod'
        shift
        ;;
    --only)
        only_pattern="${2}"
        shift 2
        ;;
    *)
        printf '%s [ERROR]: Unknown argument %s\n' "$(date "${datetime_format}")" "${1}" >&2
        exit 1
        ;;
    esac
done
if [ "${only_pattern}" = '' ]; then
    only_pattern=".*"
fi
HOMELAB_ENV="${mode}"

alias drawio='/Applications/draw.io.app/Contents/MacOS/draw.io'
diagrams_dir="$(dirname "${0}")"

PATH="$(dirname "${0}")/node_modules/.bin:${PATH}"
export PATH

optimize_diagram() {
    # ${1} - generated PNG
    if [ "${HOMELAB_ENV-x}" = 'dev' ] || [ ! -f "${1}" ]; then
        return 0
    fi

    tmpdir="$(mktemp -d)"
    tmpfile="${tmpdir}/$(basename "${1}")"

    cp "${1}" "${tmpfile}"
    oxipng --opt max --strip safe --force "${tmpfile}"
    if [ "$(wc -c <"${tmpfile}")" -lt "$(wc -c <"${1}")" ]; then
        cp "${tmpfile}" "${1}"
    fi

    # cp "${1}" "${tmpfile}"
    # zopflipng --iterations=100 --filters=01234mepb --lossy_8bit --lossy_transparent -y "${tmpfile}" "${tmpfile}"
    # if [ "$(wc -c <"${tmpfile}")" -lt "$(wc -c <"${1}")" ]; then
    #     cp "${tmpfile}" "${1}"
    # fi

    rm -rf "${tmpdir}"
}

# Mermaid CLI generates the PNG diagram with unbalanced margins on left and right side, so this function fixes it
center_diagram() {
    homelab_png="${1}"
    homelab_size="$(magick identify -format '%wx%h' "${homelab_png}")"
    homelab_tmpdir="$(mktemp -d)"
    homelab_tmpfile="${homelab_tmpdir}/$(basename "${homelab_png}")"

    magick "${homelab_png}" -bordercolor '#222230' -border 11x0 -crop "${homelab_size}+0+0" +repage "${homelab_tmpfile}"
    cp "${homelab_tmpfile}" "${homelab_png}"
    rm -rf "${homelab_tmpdir}"
}

build_diagram() {
    # ${1} - diagram name
    input_extension="$(printf '%s' "${1}" | sed -E 's~^.+\.~~')"
    output_file="$(printf '%s' "${1}" | sed -E 's~src/~~;s~\.[^.]+$~.png~')"
    output_extension="$(printf '%s' "${output_file}" | sed -E 's~^.+\.~~')"
    mkdir -p "$(dirname "${diagrams_dir}/out/${output_file}")"

    if [ "${input_extension}" = 'mmd' ]; then
        mmdc --scale 3 --backgroundColor '#222230' --input "${diagrams_dir}/${1}" --output "${diagrams_dir}/out/${output_file}" --cssFile "${diagrams_dir}/style.css"
    elif [ "${input_extension}" = 'ts' ]; then
        tsx "${diagrams_dir}/${1}"
        drawio -x -f png --scale 2 --border 100 -o "${diagrams_dir}/out/${output_file}" "${diagrams_dir}/$(printf '%s' "${1}" | sed -E 's~\.ts$~~').drawio"
    elif [ "${input_extension}" = 'drawio' ]; then
        drawio -x -f png --scale 2 --border 100 -o "${diagrams_dir}/out/${output_file}" "${diagrams_dir}/${1}"
    fi

    if [ "${input_extension}" = 'mmd' ] && [ "${output_extension}" = 'png' ]; then
        center_diagram "${diagrams_dir}/out/${output_file}"
    fi

    optimize_diagram "${diagrams_dir}/out/${output_file}"
}

find src -name '*.mmd' | grep "${only_pattern}" | while read -r file; do
    build_diagram "${file}"
done
find src -name '*.ts' -maxdepth 1 | grep "${only_pattern}" | while read -r file; do
    build_diagram "${file}"
done
