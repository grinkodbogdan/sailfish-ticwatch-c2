#!/bin/bash
# AsteroidOS skipjack kernel + its initramfs patched to boot /data/sailfish.ext4
# -> sailfish-boot.img (fastboot boot it; AsteroidOS stays the default boot).
set -euo pipefail
cd "$(dirname "$0")"
# cpio as root:root with a /dev/console node, without needing real root.
fakeroot sh -c '
  cd ramdisk
  mkdir -p dev && rm -f dev/console && mknod -m 600 dev/console c 5 1
  find . | sort | cpio -o -H newc --quiet | gzip -9 > ../sailfish-initrd.img
'
mkbootimg --kernel zImage --ramdisk sailfish-initrd.img \
  --base 0x80100000 --kernel_offset 0x00008000 --ramdisk_offset 0x02000000 \
  --tags_offset 0x01e00000 --pagesize 2048 \
  --cmdline "buildvariant=user selinux=0 SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1 audit=0 firmware_class.path=/vendor/firmware" \
  -o sailfish-boot.img
ls -l sailfish-boot.img
