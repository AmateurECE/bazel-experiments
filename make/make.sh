#!/usr/bin/env bash

set -x
set -e

printenv

IFS=:; set -o noglob
for path in $HERMETIC_TOOL_PATH; do
  export PATH="$(realpath $path):$PATH"
done

make ${BUILDDIR_VARIABLE}=$PWD -j$(nproc) -l$(nproc) $@

IFS=:; set -o noglob
for artifact in $INSTALL_ARTIFACTS; do
  install -t $OUT_DIR $artifact
done
