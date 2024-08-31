#!/usr/bin/env bash

set -x
set -e

printenv

# Some scripts require HOME to be set.
export HOME=$PWD

IFS=:; set -o noglob
for path in $HERMETIC_TOOL_PATH; do
  export PATH="$(realpath $path):$PATH"
done

if [[ -n ${BUILDDIR_VARIABLE} ]]; then
  # if BUILDDIR_VARIABLE is provided, perform an out-of-tree build where
  # BUILD_DIR is $PWD.
  BUILD_DIR=$PWD
  BUILD_SPECIFICATION="${BUILDDIR_VARIABLE}=${BUILD_DIR}"
else
  # if BUILDDIR_VARIABLE is not provided, assume that out-of-tree builds are
  # not supported, so BUILD_DIR will also be SRC_DIR.
  BUILD_DIR=$SRC_DIR
fi

IFS=":"; set -o noglob
for target in $MAKE_TARGETS; do
  make $BUILD_SPECIFICATION -j$(nproc) -l$(nproc) -C $SRC_DIR $@ $target
done

IFS=:; set -o noglob
for artifact in $INSTALL_ARTIFACTS; do
  install -t $OUT_DIR $BUILD_DIR/$artifact
done
