# AERA Recovery — Samsung Galaxy A35 5G (SM-A356E)

> **Status: clean AERA port workspace — not yet build-ready, not compiled, and not tested on-device.**

This repository is reserved for an independent **AERA Recovery 16.0** device port for the Samsung Galaxy A35 5G (`a35x`). It is intentionally kept separate from the existing SHRP project.

At this stage, this repository contains documentation only. No speculative device configuration, copied build files, proprietary binaries, or unverified recovery scripts are included.

## What is already known

| Item | Current evidence |
|---|---|
| Target model | Samsung Galaxy A35 5G — SM-A356E |
| Device family / codename | `a35x` |
| SoC | Samsung Exynos 1380 |
| Platform identifiers seen in the existing device work | `s5e8835` / `erd8835` |
| Existing recovery development base | A separate A35X SHRP device-tree effort, initially adapted from an A54X recovery tree |
| Stock boot container examined for the A35X work | Android boot image header v4; 4096-byte page size |
| Extracted ARM64 kernel payload from that supplied boot image | 38,246,912 bytes |
| SHA-256 of that extracted kernel payload | `7617639544b7be8c8209cac9644553ba795e7b27d5f51cc0fad2505a976349e1` |
| Ramdisk in that supplied boot image | 0 bytes |

These values describe the supplied boot image that was examined during the earlier A35X recovery work. They do **not** prove that its kernel, DTB, DTBO, vendor modules, or firmware components are interchangeable with every installed firmware revision. Verify provenance and compatibility against the exact device firmware before using them.

## Existing recovery work — kept separate

The A35X SHRP project is a separate development effort and remains the reference for the device-specific recovery investigation already performed. Its history includes work derived from an A54X recovery device tree and subsequent A35X adaptations.

That work is useful as a source of device research, observations, and test results. It is **not** an AERA 16.0 device tree, and SHRP/TWRP-specific make variables or product definitions must not be assumed to work in AERA.

- A35X SHRP device tree: https://github.com/christiandroid20/shrp_device_samsung_a35x
- A54X recovery-tree reference: https://github.com/daglaroglou/android_device_samsung_a54x

## Work still required for AERA 16.0

1. Confirm the official AERA manifest, build instructions, required branch, and recovery-core revision.
2. Inspect the AERA build system and identify its actual device/product integration points.
3. Create the A35X product files and board configuration from verified requirements rather than guessed or inherited flags.
4. Audit the exact firmware's boot image, vendor_boot, DTB/DTBO, kernel, fstab, partition map, and module compatibility.
5. Bring up display, touch, USB, ADB, storage access, and recovery logging independently.
6. Validate partition mounting and recovery behavior without formatting or modifying userdata.
7. Investigate FBE decryption, KeyMint, Gatekeeper, and TEEGRIS as a separate stage. A recovery that boots successfully does not necessarily support encrypted-data decryption.
8. Build, inspect, and test a recovery image only after the configuration and boot chain are understood.

## Repository policy

- Keep this AERA port independent from SHRP; do not merge the two projects' build files blindly.
- Add only files whose purpose, source, and compatibility have been checked.
- Do not commit proprietary Samsung firmware blobs unless redistribution is explicitly authorized.
- Do not include extracted kernel or firmware binaries until their exact source firmware and redistribution status are documented.
- Do not change the device bootloader, binary revision, modem, PIT, or partition layout as part of this recovery bring-up.
- Do not format, wipe, or write to userdata during initial bring-up. Treat userdata inspection as read-only.
- Never mix kernel, DTB, DTBO, vendor modules, or firmware components from unrelated builds.
- Keep known-good stock images and a complete matching firmware package available before any device test.

## Upstream references

- AERA website: https://aera-recovery.com/
- AERA documentation: https://aera-recovery.com/wiki/
- AERA manifest: https://github.com/AERA-Recovery/android_manifest
- AERA recovery core: https://github.com/AERA-Recovery/android_bootable_recovery

## Current deliverable

This repository is currently a clean starting point and documentation record. **There is no AERA device tree, successful AERA build, flashable image, or confirmed on-device AERA boot yet.** Those will be added only after the upstream build requirements and A35X hardware baseline have been verified.
