#!/usr/bin/env bash

set -e

while getopts ":o:f:" flag; do
  case "$flag" in
    o) OUTPUT_DIRECTORY=$OPTARG;;
    f) FILE_NAME=$OPTARG;;
  esac
done

INPUT=${@:$OPTIND}

# Ensure the output directory exists.
mkdir -p $OUTPUT_DIRECTORY

# Copy input executable to output directory.
init=$OUTPUT_DIRECTORY/init
install -m755 $INPUT $init

# Grab shared libraries from the toolchain
IFS=$'\n'; shared_libraries=($(readelf -d $INPUT | grep 'Shared library' | sed 's/^[^[]*\[\([^]]\+\)\].*$/\1/'))

# Fix the runpath
IFS=':'; runpath=($(readelf -d $INPUT | grep 'Library runpath' | sed 's/^[^[]*\[\([^]]\+\)\].*$/\1/'))

unset IFS

libdir=$OUTPUT_DIRECTORY/lib
mkdir -p $OUTPUT_DIRECTORY/lib
for shared_library in "${shared_libraries[@]}"; do
  for directory in "${runpath[@]}"; do
    file=$directory/$shared_library
    if [ -f $file ]; then
      install -m755 $file $libdir
    fi
  done
done

patchelf --set-rpath /lib $init

# Fix the interpreter
interpreter=$(readelf -p .interp $INPUT | awk '/\.so/{print $3}')

install -m755 $interpreter $libdir

patchelf --set-interpreter /lib/$(basename $interpreter) $init

# Stuff into a cpio archive
(cd $OUTPUT_DIRECTORY && find . ! -path . ! -path ./archive-contents.txt ! -path ./$FILE_NAME) \
  >$OUTPUT_DIRECTORY/archive-contents.txt
(cd $OUTPUT_DIRECTORY && cpio -o -H newc -R 0:0) \
  <$OUTPUT_DIRECTORY/archive-contents.txt >$FILE_NAME
