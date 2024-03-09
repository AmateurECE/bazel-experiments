#!/usr/bin/env bash

while getopts "f:s:o:" flag; do
  case "$flag" in
    f) FSBL=$OPTARG;;
    s) SSBL=$OPTARG;;
    o) IMAGE=$OPTARG;;
  esac
done

ROOTFS_CONTENTS=(${@:$OPTIND})

cat $FSBL $SSBL ${ROOTFS_CONTENTS[@]} > $IMAGE
truncate -s 1G $IMAGE
