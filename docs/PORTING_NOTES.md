# Notas de port SHRP 12.1 -> AERA 16.0 (a35x)

Origen: `shrp_device_samsung_a35x-merge-f218c7a-into-fkeymaster` (zip subido el 2026-11-13).
Referencia: https://aera-recovery.com/wiki/ (no pude abrir los repos infiniti/lighthouse; no se comparó contra ellos).

## Qué cambié (solo capa de build)
| Archivo | Cambio |
|---|---|
| `omni_a35x.mk` -> `twrp_a35x.mk` | `PRODUCT_NAME := twrp_a35x` (el wiki conserva el prefijo `twrp_`) |
| `AndroidProducts.mk` | lunch `twrp_a35x-bp2a-eng` |
| `vendorsetup.sh` | sin `add_lunch_combo`; exports con guardia `AERA_BUILD_DEVICE=a35x`; `AERA_INCLUDE_CRYPTO=true` |
| `BoardConfig.mk` | bloque `SHRP_*` comentado; añadidos `AERA_INCLUDE_CRYPTO`, `AERA_EXCLUDE_DEFAULT_USB_INIT`; avisos `VERIFICAR`/`RIESGO` |
| `README.md` | nuevo (el anterior hablaba de la A54) -> `docs/legacy/` |
| `.github/workflows/buscar-crypto-gitgud.yml` | movido a `docs/legacy/` (workflow de un solo uso que empuja a otro repo) |

**No toqué:** `prebuilt/`, `recovery/root/`, `recovery.fstab`, `sepolicy/`, `vendor.prop`, `mkbootimg.mk`, `Android.mk`, `device.mk`.

## Verificado en el zip
- Los 291 `.ko` tienen el mismo vermagic: `5.15.153-android13-3-31153516`.
- `modules.load.recovery` lista 291 módulos.
- `vendorsetup.sh` pasa `bash -n`.

## Discrepancias y riesgos encontrados
1. **README vs fstab:** el README dice que se añadieron `/keydata` y `/keyrefuge` a `recovery.fstab`, pero **no están** en el fstab del zip. O se perdieron en el merge o el README está adelantado. Resolver antes de probar `/data`.
2. **Patch level fijo:** `vendor.prop` y `BoardConfig.mk` fijan `2025-04-01` (y `2099-12-31` como placeholder). El wiki de AERA avisa que KeyMint debe arrancar con las propiedades del ROM realmente instalado; valores fijos pueden causar upgrades inválidos de keyblob. Si el ROM del teléfono se actualiza, esto deja de coincidir.
3. **Kernel/dtb:** no pude leer la cadena de versión de `prebuilt/Image` con `strings` (solo aparece el formato `Linux version %s`). El README afirma que es el kernel stock con el mismo vermagic; compruébalo en el teléfono (`uname -r` / `dmesg`).
4. **Android 12.1 -> 16:** `PRODUCT_TARGET_VNDK_VERSION := 33`, `PRODUCT_SHIPPING_API_LEVEL := 32`, los `PLATFORM_*` forzados, `mkbootimg.mk` (usa variables `recovery_kernel`/`recovery_ramdisk` de 12.1) y la capa `BOARD_*IMAGE_FILE_SYSTEM_TYPE` pueden no compilar o no tener efecto en 16.0. Sin el árbol de referencia no puedo decir cuáles.
5. **Tamaño:** recovery.img rondaba el límite de la partición (README de BoardConfig: se pasó por 3.678.208 bytes). Hay carga prescindible en `recovery/root`: ~291 módulos (incluye decenas de `hid-*`), firmware `RTP*`/haptics, fuentes y sonidos de `system/media`, y `s3907_a54x.bin` (sobrante de la A54).
6. **Blobs Samsung:** `recovery/root/` contiene binarios y TAs extraídos del firmware stock. Revisa licencia y si quieres publicarlos en un repo público.
7. **Nombre de lunch:** el README viejo decía `twrp_a54x`; el producto real era `omni_a35x`. Ya unificado a `twrp_a35x`.

## Pendiente (necesito el árbol de referencia o el manifest)
- Dónde coloca AERA cada flag (BoardConfig vs device.mk vs vendorsetup).
- Secuencia de arranque de KeyMint/gatekeeper con propiedades reales del ROM.
- Si hace falta `aera_a35x.mk` en vez de `twrp_a35x.mk`.
- URL y rama exactas del manifest de AERA 16.0.

## Probar en hardware (nada de esto está confirmado)
`ls -la /dev/block/by-name/`, `dmesg | grep -iE "ufs|mmc|block"`, y `a35x-recovery-diagnostics.sh`.
