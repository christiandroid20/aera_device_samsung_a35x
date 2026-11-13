# A35X AERA native plugins

This directory contains two AERA Host API 2 workers:

- **GSI MANAGER** — read-only image inspection, SHA-256, physical/logical partition inventory, Samsung compatibility properties, snapshot discovery and boot-image status.
- **EMERGENCY MODE** — read-only boot-reason, pstore, filesystem, TEE/decryption and recovery-log diagnostics.

Both workers run as root in the recovery environment. Their first prototype deliberately contains no block-device write, format, boot patch, reboot, automatic rollback or userdata wipe operation. Features that would modify images are shown as disabled until their transaction and recovery safeguards are implemented.

## Build

From the AERA 16.0 source root:

```sh
export AERA_BUILD_DEVICE=a35x
source build/envsetup.sh
bash device/samsung/a35x/plugins/build_plugins.sh
lunch twrp_a35x-bp2a-eng
m -j2 recoveryimage
```

The script uses AERA's AArch64 musl sysroot and Clang prebuilts. Set `AERA_TREE`, `AERA_CLANG` or `AERA_BUILTINS` only when the checkout uses a non-default location.

The generated runtime payloads and finalized manifests are staged into:

`recovery/root/system/etc/aera/plugins/{gsi-manager,emergency-mode}/`

A device init action copies these files into `/tmp/aera/plugins/` after AERA mounts its tmpfs. The AERA Home plugin grid then discovers the two device-specific apps. Local packages without the AERA project signature are marked **Unofficial** by AERA; this implementation does not alter the project's signing key or trust policy.

## Compatibility and limitations

- Host API 2 is required.
- File selection uses the Host API 2 native file picker.
- The GSI inspector currently identifies sparse, EROFS, EXT4, ZIP, payload and Android boot image headers; it does not mount or unpack selected files.
- Partition inventory is read-only.
- Emergency Mode reports evidence only. A recovery plugin cannot force the Samsung bootloader to enter recovery after failures that happen before Android init.
- The VNDK target remains a build-time validation item until the installed vendor's `ro.vndk.version` is read from the SM-A356E.
