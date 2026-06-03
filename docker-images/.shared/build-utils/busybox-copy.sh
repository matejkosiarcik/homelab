#!/bin/sh
set -euf

mkdir -p '/fsroot/bin'

# This script copies some binaries from "/bin/*" to "/fsroot/bin/"
while read -r binary; do
    cp "${binary}" "/fsroot/bin/"
done <<EOF
/bin/arch
/bin/awk
/bin/base64
/bin/basename
/bin/bc
/bin/cat
/bin/cmp
/bin/comm
/bin/cp
/bin/crc32
/bin/cut
/bin/date
/bin/dd
/bin/diff
/bin/dirname
/bin/echo
/bin/egrep
/bin/env
/bin/expand
/bin/false
/bin/fgrep
/bin/find
/bin/flock
/bin/fsync
/bin/getopt
/bin/grep
/bin/gunzip
/bin/gzip
/bin/head
/bin/kill
/bin/ln
/bin/ls
/bin/md5sum
/bin/mkdir
/bin/mkfifo
/bin/mv
/bin/nohup
/bin/nproc
/bin/patch
/bin/printenv
/bin/printf
/bin/pwd
/bin/realpath
/bin/rm
/bin/rmdir
/bin/sed
/bin/seq
/bin/sh
/bin/sha1sum
/bin/sha256sum
/bin/sha3sum
/bin/sha512sum
/bin/sleep
/bin/sort
/bin/tail
/bin/tar
/bin/tee
/bin/time
/bin/timeout
/bin/touch
/bin/tr
/bin/true
/bin/uname
/bin/unexpand
/bin/uniq
/bin/unzip
/bin/watch
/bin/wc
/bin/which
/bin/xargs
/bin/xz
/bin/yes
EOF
