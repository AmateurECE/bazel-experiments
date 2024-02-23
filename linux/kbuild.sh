#!/usr/bin/env bash

set -e
set -x

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

printf "CONFIG_INITRAMFS_SOURCE=\"$INITRAMFS_SOURCE\"\n" > $B/initramfs.cfg
(cd $B && $KDIR/scripts/kconfig/merge_config.sh -m \
  initramfs.cfg $KDIR/arch/$ARCH/configs/$DEFCONFIG > .config)

make O=$B ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -C $KDIR olddefconfig
make O=$B ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -C $KDIR -j$(nproc)

install $B/.config -t $OUT_DIR
install $B/arch/$ARCH/boot/$IMAGE -t $OUT_DIR
install $B/arch/$ARCH/boot/dts/$DTB -t $OUT_DIR
