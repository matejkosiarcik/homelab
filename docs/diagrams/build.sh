#!/bin/sh
set -euf

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
        printf 'Unknown argument %s\n' "${1}"
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

build_diagram() {
    # ${1} - diagram name
    extension="$(printf '%s' "${1}" | sed -E 's~^.+\.~~')"
    output_file="$(printf '%s' "${1}" | sed -E 's~src/~~;s~\.[^.]+$~.png~')"
    mkdir -p "$(dirname "${diagrams_dir}/out/${output_file}")"

    if [ "${extension}" = 'mmd' ]; then
        mmdc --scale 3 --backgroundColor '#222230' --input "${diagrams_dir}/${1}" --output "${diagrams_dir}/out/${output_file}" --cssFile "${diagrams_dir}/style.css"
    elif [ "${extension}" = 'ts' ]; then
        tsx "${diagrams_dir}/${1}"
        drawio -x -f png --scale 2 --border 100 -o "${diagrams_dir}/out/${output_file}" "${diagrams_dir}/$(printf '%s' "${1}" | sed -E 's~\.ts$~~').drawio"
    elif [ "${extension}" = 'drawio' ]; then
        drawio -x -f png --scale 2 --border 100 -o "${diagrams_dir}/out/${output_file}" "${diagrams_dir}/${1}"
    fi

    optimize_diagram "${diagrams_dir}/out/${output_file}"
}

find src -name '*.mmd' | grep "${only_pattern}" | while read -r file; do
    build_diagram "${file}"
done
find src -name '*.ts' -maxdepth 1 | grep "${only_pattern}" | while read -r file; do
    build_diagram "${file}"
done
