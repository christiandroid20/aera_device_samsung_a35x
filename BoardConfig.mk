#
# Copyright (C) 2026 AERA Recovery Project contributors
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/samsung/a35x

# Minimal AERA 16.0 manifest compatibility
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_NINJA_USES_ENV_VARS += RTIC_MPGEN
BUILD_BROKEN_PLUGIN_VALIDATION := soong-libaosprecovery_defaults soong-libguitwrp_defaults soong-libminuitwrp_defaults soong-vold_defaults

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

# Bootloader / Exynos platform
BOARD_VENDOR := samsung
PRODUCT_PLATFORM := s5e8835
TARGET_BOOTLOADER_BOARD_NAME := s5e8835
TARGET_SOC := s5e8835
TARGET_BOARD_PLATFORM := erd8835
TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true
TARGET_USES_UEFI := true
TARGET_USES_64_BIT_BINDER := true

# Kernel baseline: extracted from the supplied SM-A356E boot.img.
# Audited container: A356EXXU4BYDC, Android boot header v4, 4096-byte pages.
# The header's os_version field encodes 13.0.0 / 2025-04; this metadata alone
# does not establish the Android framework/vendor release of the full firmware.
# Keep all proprietary firmware binaries local; do not commit without permission.
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)

# Dedicated recovery partition (carried over from the existing A35 tree).
# MUST be confirmed against the exact SM-A356E partition map before packaging.
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 100663296

# Dynamic partitions — carried over from the existing A35 tree; verify against
# the target firmware's super partition metadata before device testing.
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := samsung_dynamic_partitions
BOARD_SAMSUNG_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor odm vendor_dlkm system_dlkm
BOARD_SAMSUNG_DYNAMIC_PARTITIONS_SIZE := 9122611200

# Filesystems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_USES_METADATA_PARTITION := true
BOARD_AVB_ENABLE := false
PRODUCT_USE_DYNAMIC_PARTITIONS := true
RECOVERY_SDCARD_ON_DATA := true

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
AERA_THEME := portrait_hdpi
AERA_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
AERA_INCLUDE_FASTBOOTD := true
AERA_SKIP_ADDITIONAL_FSTAB := true
AERA_USE_DMCTL := true
AERA_INCLUDE_LPDUMP := true
AERA_INCLUDE_LPTOOLS := true
AERA_INCLUDE_REPACKTOOLS := true
AERA_INCLUDE_RESETPROP := true
AERA_INCLUDE_LIBRESETPROP := true
AERA_INCLUDE_LOGCAT := true
AERA_ENABLE_FS_COMPRESSION := true
AERA_USE_TOOLBOX := true
TARGET_USES_LOGD := true

# Encryption build support is enabled for testing only. This does NOT mean
# A35 FBE decryption is working; KeyMint/Gatekeeper/TEEGRIS runtime integration
# must be validated independently before claiming successful decryption.
AERA_INCLUDE_CRYPTO := true
AERA_INCLUDE_CRYPTO_FBE := true
AERA_INCLUDE_FBE_METADATA_DECRYPT := true
AERA_USE_FSCRYPT_POLICY := 2

# Initial bring-up: do not bundle optional AERA root-manager modules.
AERA_ENABLE_ROOT_MANAGER := 0
