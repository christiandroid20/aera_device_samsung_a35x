# A35x recovery startup baseline (diagnostic only)

Branch: `debug/a35x-recovery-startup-baseline-20261030`

This branch is a controlled startup test based on the TeamWin A35x `android-12.1` device-tree init sequence.

## What changed

- Restored the A35x init startup sequence used by TeamWin.
- Restored `sys.usb.controller=13200000.dwc3`, root ADB properties, and the initial ADB USB configuration.
- Restored the `/dev/block/bootdevice` and `/dev/block/by-name` symlinks, plus the original `param` symlink and Android root export.
- Added the A35x platform identifiers `TARGET_SOC=s5e8835`, `TARGET_NO_RADIOIMAGE=true`, and `TARGET_USES_UEFI=true`.
- Deliberately stopped importing `init.recovery.teegris.rc` for this test.
- Disabled TWRP crypto/FBE build flags for this test.

## Important limitation

**This is not a usable daily recovery and cannot decrypt /data.** TEEGRIS and KeyMint startup are intentionally excluded so the boot UI and USB/ADB path can be tested independently. Do not use it for data operations, formatting, wiping, flashing partitions, or backups that require decrypted /data.

## Build

Use the builder repository workflow `SkyHawk [SHRP]` from branch `fix-a35-vendor-patch-and-diagnostics`, and set:

- Manifest branch: `shrp-12.1`
- Device tree branch: `debug/a35x-recovery-startup-baseline-20261030`
- Build target: `recovery`

Confirm the build log reports the intended device-tree commit before testing.

## Test objective

Only establish whether the recovery reaches the SHRP interface and whether ADB enumerates over USB. A successful result does not establish that encryption/decryption works. Reintroduce TEEGRIS and crypto only after the startup baseline is confirmed.
