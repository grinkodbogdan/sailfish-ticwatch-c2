#!/bin/bash
# Build the Android side (hybris-hal: kernel, boot/recovery images, bionic,
# init, servicemanager...) for Sailfish OS on TicWatch C2 (skipjack).
# Runs inside the sfos-skipjack-aosp container with the tree at /src.
#
#   docker run --rm -v ~/sfos-skipjack:/src sfos-skipjack-aosp /env/build-hal.sh
set -euo pipefail
cd /src

# 1. hybris patches (once). The script wants ./hybris-patches at the top.
if [ ! -e .hybris-patched ]; then
  ln -sfn hybris/hybris-patches hybris-patches
  hybris/hybris-patches/apply-patches.sh
  touch .hybris-patched
fi

# 2. AOSP 9 build environment.
set +u
source build/envsetup.sh
export LC_ALL=C
export ALLOW_MISSING_DEPENDENCIES=true   # trimmed tree: cts/tests are gone
export TEMPORARY_DISABLE_PATH_RESTRICTIONS=true
lunch aosp_skipjack-user
set -u

# 3. hybris-hal (4 jobs: 14 GB RAM).
make -j"${JOBS:-4}" hybris-hal 2>&1 | tee /src/hybris-hal.log
echo "BUILD-HAL DONE"
