#!/bin/bash
# Copyright (C) 2026 AERA Recovery Project contributors
# SPDX-License-Identifier: GPL-3.0-or-later

FDEVICE="a35x"

if [ "${1:-}" = "$FDEVICE" ] || [ "${AERA_BUILD_DEVICE:-}" = "$FDEVICE" ]; then
    export AERA_BUILD_DEVICE="$FDEVICE"
    export LC_ALL="C"

    export AERA_PRODUCT_PREFIX=AERA
    export AERA_BUILD_STATUS=Unofficial
    export AERA_BUILD_TYPE=Alpha
    export AERA_VANILLA_BUILD=1

    export AERA_ENABLE_ROOT_MANAGER=0
    export AERA_USE_DMSETUP=1
    export AERA_USE_TAR_BINARY=1
    export AERA_USE_SED_BINARY=1
    export AERA_USE_LZ4_BINARY=1
    export AERA_USE_ZSTD_BINARY=1
    export AERA_USE_DATE_BINARY=1
    export AERA_USE_GREP_BINARY=1
    export AERA_USE_BUSYBOX_BINARY=1
    export AERA_USE_XZ_UTILS=1
    export AERA_USE_FSCK_EROFS_BINARY=1
    export AERA_USE_PATCHELF_BINARY=1
    export AERA_ALLOW_EARLY_SETTINGS_LOAD=1
    export AERA_USE_UPDATED_MAGISKBOOT=1

    export AERA_SETTINGS_ROOT_DIRECTORY=/metadata
    export AERA_MISCELLANEOUS_ROOT_DIRECTORY=/sdcard

    export TARGET_DEVICE_ALT="a35x,SM-A356E"
    export AERA_TARGET_DEVICES="$TARGET_DEVICE_ALT"

    unset AERA_MAINTAINER_PATCH_VERSION
fi
