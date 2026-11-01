# AERA 16.0 device-variable compatibility audit

The AERA 16.0 recovery core contains `aera_config.mk`, which translates the
public `AERA_*` device configuration names to the recovery backend's internal
TWRP/OrangeFox-compatible variables.

The following names used by this device tree are present in that translation
layer:

| Device-tree variable | Backend setting |
|---|---|
| `AERA_THEME` | `TW_THEME` |
| `AERA_BRIGHTNESS_PATH` | `TW_BRIGHTNESS_PATH` |
| `AERA_INCLUDE_CRYPTO` | `TW_INCLUDE_CRYPTO` |
| `AERA_INCLUDE_CRYPTO_FBE` | `TW_INCLUDE_CRYPTO_FBE` |
| `AERA_INCLUDE_FBE_METADATA_DECRYPT` | `TW_INCLUDE_FBE_METADATA_DECRYPT` |
| `AERA_INCLUDE_FASTBOOTD` | `TW_INCLUDE_FASTBOOTD` |
| `AERA_INCLUDE_LPDUMP` | `TW_INCLUDE_LPDUMP` |
| `AERA_INCLUDE_LPTOOLS` | `TW_INCLUDE_LPTOOLS` |
| `AERA_INCLUDE_REPACKTOOLS` | `TW_INCLUDE_REPACKTOOLS` |
| `AERA_INCLUDE_RESETPROP` | `TW_INCLUDE_RESETPROP` |
| `AERA_INCLUDE_LIBRESETPROP` | `TW_INCLUDE_LIBRESETPROP` |
| `AERA_INCLUDE_LOGCAT` | `TWRP_INCLUDE_LOGCAT` |
| `AERA_SKIP_ADDITIONAL_FSTAB` | `TW_SKIP_ADDITIONAL_FSTAB` |
| `AERA_USE_DMCTL` | `OF_USE_DMCTL` |
| `AERA_USE_FSCRYPT_POLICY` | `TW_USE_FSCRYPT_POLICY` |
| `AERA_USE_TOOLBOX` | `TW_USE_TOOLBOX` |
| `AERA_ENABLE_FS_COMPRESSION` | Sets `TW_ENABLE_FS_COMPRESSION` and `OF_ENABLE_FS_COMPRESSION` |

This audit is based on the AERA Recovery core branch `aera-16.0`, file
`aera_config.mk`. It confirms variable-name compatibility only; it does not
prove that the device's hardware, kernel, vendor services or encryption work.

## Device-specific settings still requiring validation

- Theme density and screen layout must be confirmed against the actual panel.
- Brightness sysfs path must be read from recovery or stock init/device data.
- Fastbootd requires working dynamic-partition and userspace fastboot support.
- Crypto flags only enable build paths; they do not supply matching KeyMint,
  Gatekeeper, TEEGRIS, TA files or vendor runtime dependencies.
