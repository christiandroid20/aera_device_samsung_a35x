# AERA Recovery — Samsung Galaxy A35 (SM-A356E)

> **Status: bring-up scaffold with kernel extracted; not yet build-ready for device testing and not tested on-device.**

Initial device-tree workspace for bringing up [AERA Recovery](https://aera-recovery.com/) on the Samsung Galaxy A35 5G (Exynos 1380, device family `a35x`).

## Bring-up strategy

1. Establish the AERA 16.0 build environment and confirm upstream manifest/core revisions.
2. Use the supplied stock boot image as a kernel source and verify all companion firmware components match it.
3. Adapt the device configuration to AERA's actual build interfaces; do not copy SHRP/TWRP-specific variables blindly.
4. Validate boot, display, touch, ADB, USB, partition access and read-only data inspection.
5. Investigate KeyMint, Gatekeeper and TEEGRIS compatibility separately. A successful recovery boot does not imply working FBE decryption.
6. Build a custom kernel only if logs and controlled tests demonstrate that the stock-kernel baseline cannot meet the requirements.

## Current evidence

- Device family: `a35x`; target model: `SM-A356E`.
- SoC/platform carried forward from the existing device tree: Exynos 1380 / `s5e8835` / `erd8835`.
- Supplied boot container: Android boot header v4, 4096-byte pages.
- Extracted ARM64 kernel payload: 38,246,912 bytes.
- Kernel SHA-256: `7617639544b7be8c8209cac9644553ba795e7b27d5f51cc0fad2505a976349e1`.
- Supplied boot image ramdisk size: zero bytes.
- Header `os_version` metadata decodes to Android 13.0.0 / April 2025; this alone does not establish the framework release of the full firmware package.

The kernel binary is not committed; place it locally at `prebuilt/Image`. Matching vendor_boot, DTBO, DTB provenance and the exact firmware fstab still need to be verified.

## Repository layout

- `docs/` — bring-up plan, firmware audit and build notes.
- `kernel/` — kernel baseline notes and future reproducible build work.
- `prebuilt/` — instructions for local, non-committed firmware binaries.
- `proprietary/` — extraction/manifest documentation only.
- `recovery/root/` — device-specific recovery-side additions, if required.

## Safety

- Keep the stock boot/recovery images and a known-good firmware package available.
- Do not format or wipe userdata as a troubleshooting shortcut.
- Initial userdata investigation must be read-only.
- Never mix kernel, DTB, DTBO or vendor modules from unrelated firmware builds.
- Do not commit proprietary Samsung blobs unless redistribution is explicitly authorized.

The existing SHRP project remains separate from this AERA port.
