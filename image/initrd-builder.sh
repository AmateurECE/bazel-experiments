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

# Initialize the /dev directory
install -d -m755 $OUTPUT_DIRECTORY/dev

# TODO: Copy /dev/console into the archive.

# Stuff into a cpio archive
(cd $OUTPUT_DIRECTORY && find . ! -path . ! -path ./archive-contents.txt ! -path ./$FILE_NAME) \
  >$OUTPUT_DIRECTORY/archive-contents.txt

(cd $OUTPUT_DIRECTORY && \
  cpio -o --reproducible --no-absolute-filenames -H newc -R 0:0) \
  <$OUTPUT_DIRECTORY/archive-contents.txt >$FILE_NAME
