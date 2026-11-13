#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 The TWRP Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Según el wiki de AERA: AERA_BUILD_DEVICE se exporta en el shell que llama,
# ANTES de `source build/envsetup.sh` (nunca dentro de este bloque), y las
# opciones de empaquetado van en exports con guardia para que no se filtren
# a otros árboles:
#
#   export AERA_BUILD_DEVICE=a35x
#   source build/envsetup.sh
#   lunch twrp_a35x-bp2a-eng
#   m -j2 recoveryimage

if [ "$AERA_BUILD_DEVICE" = "a35x" ]; then
    export ALLOW_MISSING_DEPENDENCIES=true

    # Descifrado de /data (necesita además fstab correcto y KeyMint/gatekeeper
    # compatibles; el flag solo no descifra nada).
    export AERA_INCLUDE_CRYPTO=true

    # Opciones NO activadas a propósito (el árbol no trae los drivers/firmware):
    #   AERA_ENABLE_WLAN, AERA_ENABLE_MOBILE_DATA, AERA_ENABLE_ROOT_MANAGER,
    #   AERA_ENABLE_ABL_PRESERVATION
fi
