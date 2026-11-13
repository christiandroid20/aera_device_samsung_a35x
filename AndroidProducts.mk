#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 The TWRP Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_a35x.mk

# El wiki de AERA indica que los productos de ejemplo conservan el prefijo
# twrp_ (no es branding de la UI): lunch twrp_<device>-bp2a-eng
COMMON_LUNCH_CHOICES := \
    twrp_a35x-bp2a-eng
