# AERA Recovery 16.0 — Samsung Galaxy A35 5G (SM-A356E)

> **Status: active bring-up branch; not yet compiled, booted or validated on-device. Do not flash an image from this branch until the build and ramdisk audits pass.**

This repository contains an independent AERA Recovery 16.0 device port for the Samsung Galaxy A35 5G (`a35x`, Exynos 1380 / `s5e8835` / `erd8835`). It is separate from the SHRP project.

## Current work branch

- Working branch: `aera-16.0-work`
- Base: the current AERA A35X repository `main`
- The older `aera-16.0-bringup` branch and SHRP branches are preserved.
- SHRP device-tree branches are used as read-only references; this repository is the only target of the AERA changes.

## Device baseline and image geometry

| Item | Current reference |
|---|---|
| Model | Samsung Galaxy A35 5G — SM-A356E |
| Codename | `a35x` |
| SoC / platform | Exynos 1380 / `s5e8835` / `erd8835` |
| Installed firmware used for the current audit | Android 15 U4, `A356EXXU4BYDC` |
| Recovery boot image header | v2 |
| Kernel page size configured | 4096 bytes |
| Recovery partition size | 100,663,296 bytes |
| Ramdisk compression | LZ4 disabled; previous image exceeded the partition by 3,678,208 bytes with the tested compression choice |
| Dynamic partitions | system, vendor, product, odm, vendor_dlkm and system_dlkm |

The 4 KiB page size and header v2 are retained as the A35X baseline. The TeamWin Android 16 reference uses different page-size configuration; do not copy its 16 KiB setting without validating the exact kernel, boot header and known-good image. Never increase the physical recovery partition size to conceal an oversized image.

## Implemented in the working branch

### AERA product integration

- Added `aera_a35x.mk` and inherited it from `device.mk`.
- Moved the legacy Android 12.1 `mkbootimg.mk` override out of the active device root into `docs/legacy/`; AERA 16.0 core owns recovery image packaging.
- Set the shipping API level to 34, matching the A35 launch platform.
- Kept `PRODUCT_TARGET_VNDK_VERSION := 33` provisional until the installed vendor's actual `ro.vndk.version` is checked.
- Removed the fake 2099 security-patch placeholder. The 2025-04-01 patch value remains in vendor.prop because Samsung's U4BYDC release listing reports that security patch level; verify the mounted vendor's own patch property before finalizing.
- Enabled AERA's existing Root Manager using the device-specific packaging flag. No duplicate Root Manager entry is added.
- Corrected the removable-storage fstab source/mount-point order for the observed A35X microSD and USB-OTG block devices, and set the known A35X USB gadget controller (`13200000.dwc3`). These still need an AERA mount/ADB test.
- Kept the A35X dynamic partition map, including `system_dlkm`.

### TEEGRIS / Samsung crypto startup

- Created the `/dev/block/by-name` symlinks before importing the TEEGRIS RC.
- Made EFS mounts non-blocking so a missing node cannot hold the recovery UI/ADB startup.
- Centralized TZ daemon, TZ-TS, KeyMint, Gatekeeper and FKeymaster service declarations and ordered their startup after the TEE readiness properties.
- Removed duplicate vendor service RC declarations, not the service binaries or crypto functionality. The separate PA/TUI RC files remain.
- Moved the TEE validation script to executable `/sbin/extract_ta.sh`, outside the real vendor mountpoint. It validates the real U4 vendor dm-4 and fails closed if the expected TEE files are absent.

### AERA Home applications

Two device-specific Host API 2 apps are in prototype form:

- **GSI MANAGER** — image format/size/SHA-256 inspection, physical/logical partition inventory, Samsung compatibility properties, snapshot discovery and read-only boot status.
- **EMERGENCY MODE** — boot reason/build properties, pstore evidence, filesystem mount/free-space state, TEE/decryption status and recovery-log presence.

These are source prototypes only and are **not included in the first recovery image**. Their init-time registration and payload packaging are deliberately disabled until the native plugin payloads have been built and validated. Both apps remain pending; the first build focuses on AERA recovery boot, display, touch, USB/ADB, storage and crypto startup. The existing AERA Root Manager remains separate.

## Required validation before any device test

1. Read the installed U4 values:
   ```sh
   adb shell getprop ro.vndk.version
   adb shell getprop ro.vendor.api_level
   adb shell getprop ro.build.version.security_patch
   adb shell getprop ro.vendor.build.security_patch
   ```
   Update the provisional VNDK target only from the actual vendor value.
2. Verify the AERA brightness sysfs path and maximum range. The current product file uses the TeamWin16 `panel0-backlight` path as a reference, not as a confirmed live reading.
3. Compile both plugin workers with the AERA AArch64 musl toolchain. The current plugin source has not yet been cross-compiled.
4. Build AERA 16.0 and inspect the resulting image, ramdisk, init imports, plugin payload hashes, boot header, kernel, DTB/DTBO and final recovery image size.
5. Validate display, touch, USB/ADB, MTP, storage and recovery logs separately.
6. Validate FBE/metadata decryption separately against the exact stock U4 firmware and a configured lock credential.
7. Test GSI image inspection against disposable files and a simulated partition map before adding any write-capable operation.
8. Test Emergency diagnostics and snapshot restore plans with synthetic logs and verified snapshots. Automatic three-failure fallback is not enabled: it requires proven bootloader support or a ROM-side early-boot marker and success checkpoint.

## Safety and separation rules

- Do not modify SHRP repositories or branches from this project.
- Do not change the bootloader, binary revision B:4, modem, PIT or physical partition layout.
- Do not write to boot, vendor, super, misc or userdata during initial bring-up.
- Do not format or wipe userdata or encryption metadata.
- Preserve the real Samsung vendor and TEEGRIS, KeyMint, Gatekeeper and FKeymaster components.
- Keep manual boot patching separate from automatic recovery startup; no automatic boot write is permitted.
- Do not claim that a recovery-side app can trigger recovery after a failure that occurs before the bootloader hands off control.

## Provenance and redistribution

The device tree contains prebuilt kernel/DTB/DTBO material and Samsung-related vendor/TEE files from the A35X recovery work. Their exact firmware provenance and redistribution rights must be reviewed before publishing a distributable image. Do not add further proprietary payloads unless redistribution is authorized.

## Upstream references

- AERA website: https://aera-recovery.com/
- AERA documentation: https://aera-recovery.com/wiki/
- AERA manifest: https://github.com/AERA-Recovery/android_manifest
- AERA recovery core: https://github.com/AERA-Recovery/android_bootable_recovery
- A35X SHRP device-tree reference (read-only for this project): https://github.com/christiandroid20/shrp_device_samsung_a35x
- TeamWin A35X Android 14.1 / Android 16 trees (comparison references): https://github.com/TeamWin/android_device_samsung_a35x

**Current result:** source-level integration and init/crypto corrections are staged on `aera-16.0-work`. No AERA recovery image has been built or tested from this branch yet.
