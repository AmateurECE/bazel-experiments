#!/usr/bin/env bash

set -e
set -x

kbuild() {
  make O=$B ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE \
    CC=$CC LD=$LD NM=$NM AR=$AR OBJCOPY=$OBJCOPY STRIP=$STRIP \
    OBJDUMP=$OBJDUMP \
    -C $KDIR $@
}

patch-config() {
  local base=$1; shift;

  local IFS=:; set -o noglob
  for config in $CONFIG; do
    printf "$config=${!config}\n" >> $B/local.cfg
  done

  if [[ -f $B/local.cfg ]]; then
    (cd $B && $KDIR/scripts/kconfig/merge_config.sh -m $base local.cfg)
  fi
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

DEFCONFIG=${@:$OPTIND}

kbuild $DEFCONFIG

# Patch the configuration from the environment, if necessary
mv $B/.config $B/default.cfg
patch-config $B/default.cfg
kbuild olddefconfig

kbuild -j$(nproc)

# Install the configuration
install $B/.config $OUT_DIR/$NAME.cfg

IFS=:; set -o noglob
for artifact in $ARTIFACTS; do
  install $B/$artifact -t $OUT_DIR
done
