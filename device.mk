#
# Galaxy A35 5G (a35x) — AERA Recovery 16.0
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/samsung/a35x

# The Galaxy A35 launched with Android 14 (API 34). Keep the shipping API
# distinct from the currently installed Android 15 U4 firmware.
BOARD_SHIPPING_API_LEVEL := 34
PRODUCT_SHIPPING_API_LEVEL := 34
PRODUCT_TARGET_VNDK_VERSION := 33 # TODO: verify against ro.vndk.version from the installed SM-A356E vendor

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Samsung KeyMint hardware properties, kept as product vendor properties.
PRODUCT_VENDOR_PROPERTIES += \\
    ro.security.keystore.keytype=sakv2,gak,rkp \\
    ro.hardware.keystore=mdfpp \\
    ro.hardware.keystore_desede=true

TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 2340

PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# Device-specific AERA product options.
$(call inherit-product, $(LOCAL_PATH)/aera_a35x.mk)
