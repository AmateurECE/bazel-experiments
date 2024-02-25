#!/usr/bin/env bash

set -e
set -x

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

# Extract linked shared libraries
IFS=$'\n'; shared_libraries=($(readelf -d $INPUT | grep 'Shared library' | sed 's/^[^[]*\[\([^]]\+\)\].*$/\1/'))

# Extract the library runpath
IFS=':'; runpath=($(readelf -d $INPUT | grep 'Library runpath' | sed 's/^[^[]*\[\([^]]\+\)\].*$/\1/'))

unset IFS

# Install shared libraries from the toolchain into the root filesystem
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

# Fix library runpath
patchelf --set-rpath /lib $init

# Fix the interpreter
interpreter=$(readelf -p .interp $INPUT | awk '/\.so/{print $3}')
install -m755 $interpreter $libdir
patchelf --set-interpreter /lib/$(basename $interpreter) $init

# Initialize the /dev directory
install -d -m755 $OUTPUT_DIRECTORY/dev

# Stuff into a cpio archive
(cd $OUTPUT_DIRECTORY && find . ! -path . ! -path ./archive-contents.txt ! -path ./$FILE_NAME) \
  >$OUTPUT_DIRECTORY/archive-contents.txt

# Copy /dev/console into the archive.
# TODO: This is non-hermetic
printf '/dev/console\n' >> $OUTPUT_DIRECTORY/archive-contents.txt

(cd $OUTPUT_DIRECTORY && \
  cpio -o --reproducible --no-absolute-filenames -H newc -R 0:0) \
  <$OUTPUT_DIRECTORY/archive-contents.txt >$FILE_NAME
