# A35X AERA native plugins

This directory contains two AERA Host API 2 workers:

- **GSI MANAGER** — read-only image inspection, SHA-256, physical/logical partition inventory, loaded Samsung compatibility properties, snapshot discovery and boot-image status. Super metadata parsing and full HAL/VINTF/SELinux comparison are still pending.
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

**Pending for a later stage:** runtime payload generation, system image packaging and init-time registration are not currently wired into the first AERA recovery build. The init copy action is intentionally disabled until both plugin binaries and manifests are validated. Local package trust/signing policy will remain unchanged.

## Compatibility and limitations

- Host API 2 is required.
- File selection uses the Host API 2 native file picker.
- The GSI inspector currently identifies sparse, EROFS, EXT4, ZIP, payload and Android boot image headers; it does not mount or unpack selected files.
- Partition inventory currently lists by-name and mapper devices; it does not yet parse the super metadata table with lpdump.
- Partition inventory is read-only.
- Emergency Mode reports evidence only. A recovery plugin cannot force the Samsung bootloader to enter recovery after failures that happen before Android init.
- The VNDK target remains a build-time validation item until the installed vendor's `ro.vndk.version` is read from the SM-A356E.
