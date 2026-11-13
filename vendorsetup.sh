#
# Galaxy A35 5G (a35x) — AERA Recovery 16.0 packaging options
# SPDX-License-Identifier: Apache-2.0
#
# Export AERA_BUILD_DEVICE=a35x before sourcing build/envsetup.sh.

if [ "$AERA_BUILD_DEVICE" = "a35x" ]; then
    export LC_ALL="C"
    export AERA_PRODUCT_PREFIX=AERA
    export AERA_BUILD_STATUS=Unofficial
    export AERA_BUILD_TYPE=Beta
    export AERA_VANILLA_BUILD=1

    export AERA_USE_TAR_BINARY=1
    export AERA_USE_SED_BINARY=1
    export AERA_USE_LZ4_BINARY=1
    export AERA_USE_ZSTD_BINARY=1
    export AERA_USE_DATE_BINARY=1
    export AERA_USE_GREP_BINARY=1
    export AERA_USE_BUSYBOX_BINARY=1
    export AERA_USE_XZ_UTILS=1
    export AERA_USE_UPDATED_MAGISKBOOT=1
    export AERA_DELETE_MAGISK_ADDON=1
    export AERA_USE_FSCK_EROFS_BINARY=1
    export AERA_USE_PATCHELF_BINARY=1
    export AERA_USE_DMSETUP=1

    export AERA_SETTINGS_ROOT_DIRECTORY=/data/recovery
    export AERA_MISCELLANEOUS_ROOT_DIRECTORY=/sdcard

    # Requested existing AERA Root Manager; do not add a second root menu.
    export AERA_ENABLE_ROOT_MANAGER=1
fi
