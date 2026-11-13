#
# Galaxy A35 5G (a35x) — AERA Recovery 16.0
# Hardware configuration based on the SM-A356E Android 15 U4 device tree.
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/samsung/a35x

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a-branchprot
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a55

# Samsung / Exynos 1380
TARGET_SOC := s5e8835
TARGET_BOOTLOADER_BOARD_NAME := s5e8835
TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true
TARGET_USES_UEFI := true
TARGET_BOARD_PLATFORM := $(PRODUCT_PLATFORM)

# Prebuilt kernel and device trees
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_KERNEL_IMAGE_NAME := Image
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/$(BOARD_KERNEL_IMAGE_NAME)
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_INCLUDE_RECOVERY_DTBO := true
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img

# Keep the known A35 recovery image compression choice; do not enlarge the
# physical recovery partition to accommodate an oversized image.
BOARD_RAMDISK_USE_LZ4 := false

# A35 recovery uses boot image header v2 with embedded kernel + DTB.
BOARD_BOOT_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x10000000
BOARD_KERNEL_CMDLINE := bootconfig buildtime_bootconfig=enable loop.max_part=7
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x00000000
BOARD_KERNEL_TAGS_OFFSET := 0x00000000
BOARD_DTB_OFFSET := 0x00000000

BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --board "SRPWK02A003"
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)

# Recovery root directories required by Samsung init / partition handling.
BOARD_ROOT_EXTRA_FOLDERS := \
    carrier \
    efs \
    optics \
    prism \
    spu \
    system_dlkm

# SELinux
BOARD_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy

# AVB is handled by the installed Samsung boot chain; this recovery build
# does not sign or replace boot-chain partitions.
BOARD_AVB_ENABLE := false

# Physical partition sizes (bytes). Never increase these to hide image overflow.
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 100663296

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Dynamic super partition. system_dlkm is present in the A35 recovery fstab.
BOARD_SUPER_PARTITION_SIZE := 12582912000
BOARD_SUPER_PARTITION_GROUPS := group_basic
BOARD_GROUP_BASIC_SIZE := 12578717696
BOARD_GROUP_BASIC_PARTITION_LIST := system odm product vendor vendor_dlkm system_dlkm

BOARD_PARTITION_LIST := $(call to-upper, $(BOARD_GROUP_BASIC_PARTITION_LIST))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

# Samsung metadata encryption / FBE v2 support.
BOARD_USES_METADATA_PARTITION := true
AERA_INCLUDE_CRYPTO := true
AERA_INCLUDE_CRYPTO_FBE := true
AERA_INCLUDE_FBE_METADATA_DECRYPT := true
AERA_USE_FSCRYPT_POLICY := 2

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
RECOVERY_SDCARD_ON_DATA := true
TARGET_USES_MKE2FS := true

# AERA 16.0 configuration (only documented AERA namespace flags).
AERA_INCLUDE_FASTBOOTD := true
AERA_SKIP_ADDITIONAL_FSTAB := true
AERA_UI_ADAPTIVE_RESOLUTION := true
AERA_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
AERA_INCLUDE_LPDUMP := true
AERA_INCLUDE_LPTOOLS := true
AERA_INCLUDE_REPACKTOOLS := true
AERA_INCLUDE_RESETPROP := true
AERA_INCLUDE_LIBRESETPROP := true
AERA_EXCLUDE_APEX := true
AERA_EXCLUDE_DEFAULT_USB_INIT := true
AERA_ENABLE_FS_COMPRESSION := true
AERA_NO_EXFAT_FUSE := true
AERA_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
AERA_THEME := portrait_hdpi
AERA_DEVICE_VERSION := Samsung_Galaxy_A35
