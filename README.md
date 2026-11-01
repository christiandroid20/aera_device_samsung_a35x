# AERA Recovery — Samsung Galaxy A35 (SM-A356E)

> **Status: bring-up scaffold — not build-ready and not tested on-device.** The vendor snapshot currently available in the companion repository is Android 13, not the Android 15 target firmware.

Initial device-tree workspace for bringing up [AERA Recovery](https://aera-recovery.com/) on the Samsung Galaxy A35 5G (Exynos 1380, device family `a35x`).

## Bring-up strategy

1. Establish the AERA 16.0 build environment and confirm the upstream manifest/core revisions.
2. Reuse the matching Android 15 stock firmware kernel image and its matching DTB/DTBO as the first boot-test baseline.
3. Adapt the device configuration to AERA's actual build interfaces; do not copy SHRP/TWRP-specific variables blindly.
4. Validate boot, display, touch, ADB, USB, partition access and read-only data inspection.
5. Investigate KeyMint, Gatekeeper and TEEGRIS compatibility separately. A successful recovery boot does **not** imply working FBE decryption.
6. Build a custom kernel only if logs and controlled tests demonstrate that the stock-kernel baseline cannot meet the requirements.

## Device facts currently carried forward

- Device codename/family: `a35x`
- Model target: `SM-A356E`
- SoC: Samsung Exynos 1380
- Platform identifier observed in the existing device tree: `s5e8835` / `erd8835`
- Display: 1080 × 2340, portrait
- Existing recovery-tree boot header setting: v3
- Existing recovery-tree userdata filesystem declaration: F2FS

These are starting references from existing A35 recovery work, **not yet validated as final AERA settings**. The companion vendor snapshot reports Android 13 build `A356EXXS7CZA4` (SDK 33, vendor SPL 2026-01-01), while the planned first test target is Android 15 build `A356EXXU4BYDC`. Do not treat its fstab/blobs as matching the Android 15 target.

## Repository layout

- `docs/` — bring-up plan, validation matrix and porting notes.
- `kernel/` — kernel baseline notes and future reproducible build work.
- `proprietary/` — extraction/manifest documentation only; proprietary Samsung binaries are not included.
- `recovery/root/` — device-specific recovery-side additions, if required.

## Build status

No flashable image is provided by this initial scaffold. Build configuration, fstab, init scripts, kernel packaging and AERA product integration must be completed and reviewed before attempting a build or flash.

## Safety

- Keep the stock boot/recovery images and a known-good firmware package available.
- Do not format or wipe userdata as a troubleshooting shortcut.
- Initial userdata investigation must be read-only.
- Never mix kernel, DTB, DTBO or vendor modules from unrelated firmware builds.
- Do not commit proprietary Samsung blobs unless redistribution is explicitly authorized.

## Upstream

- AERA documentation: https://aera-recovery.com/wiki/
- AERA manifest: https://github.com/AERA-Recovery/android_manifest
- AERA recovery core: https://github.com/AERA-Recovery/android_bootable_recovery

This repository is an independent AERA porting effort. The existing SHRP project remains separate.
