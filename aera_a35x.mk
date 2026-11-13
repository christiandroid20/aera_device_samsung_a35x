#
# Galaxy A35 5G (a35x) — AERA-specific product configuration
# SPDX-License-Identifier: Apache-2.0
#

AERA_SCREEN_H := 2340
# The A35X TWRP16 reference uses panel0-backlight; verify max range on-device.
AERA_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
AERA_DEFAULT_BRIGHTNESS := 128
AERA_MAX_BRIGHTNESS := 510
AERA_DRM_FIXED_REFRESH_RATE := 120
