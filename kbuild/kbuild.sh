#!/usr/bin/env bash

set -e
set -x

kbuild() {
  make O=$B ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -C $KDIR $@
}

while getopts "C:" flag; do
  case "$flag" in
    C) KDIR=$OPTARG;;
  esac
done

if [[ -z "$O" ]]; then
  B=$PWD
else
  B=$PWD/$O
fi

# Kbuild rules in some repositories (e.g. U-boot) need $HOME to be set for
# downloading files during the build.
export HOME=$PWD

MAKE_TARGETS=(${@:$OPTIND})
DEFCONFIG=${MAKE_TARGETS[0]}
ALLTARGET=${MAKE_TARGETS[1]}

# Fix PATH variable with hermetic tools
IFS=:; for tool_path in $HERMETIC_TOOL_PATH; do
  export PATH="$(realpath $tool_path):$PATH"
done

kbuild $DEFCONFIG

kbuild -j$(nproc) $ALLTARGET

# Install the configuration
install $B/.config $OUT_DIR/$NAME.cfg

IFS=:; set -o noglob
for artifact in $ARTIFACTS; do
  install $B/$artifact -t $OUT_DIR
done
