# A35X AERA 16.0 — tree audit, GSI Manager and Emergency Mode

Status: design/audit baseline only. This document does not claim a successful build or on-device validation.

## Working boundaries

- This work is isolated on `aera-16.0-work`, based on the current AERA repository `main`.
- Preserve AERA `main`, the older `aera-16.0-bringup` branch, and every SHRP branch.
- The SHRP repository's `aera16-a35x-bringup` and `feature/gsi-manager-a35x-20261031` branches are read-only references only.
- Do not change firmware, bootloader, modem, PIT, physical partition layout, or the user's B:4 bootloader binary.
- Do not flash a device, format userdata, or perform unattended partition writes.
- Preserve Samsung vendor components and the complete TEEGRIS, KeyMint, Gatekeeper and FKeymaster chain.

## Tree comparison — initial findings

### Reference trees

- Device-specific A35X adaptation: the user's SHRP A35X tree, including its separate AERA bring-up branch, used as read-only reference material.
- TeamWin A35X `android-14.1`.
- TeamWin A35X `android-16`.
- AERA 16.0 device-tree examples: `infiniti` and `lighthouse`.
- Current AERA A35X repository `main`.

### Findings to carry into implementation

1. **AERA product integration is incomplete in current `main`.** The current tree has `twrp_a35x.mk`, but it does not contain the AERA-specific `aera_a35x.mk` product options or inherit them from `device.mk`. The read-only SHRP `aera16-a35x-bringup` reference does contain that product file and a device.mk inheritance path. Port the verified AERA-specific product settings into this repository; do not copy SHRP-only build flags.
2. **Shipping API/VNDK metadata needs correction and validation.** Current AERA `device.mk` says shipping API 32 and target VNDK 33. The A35X launched at API 34. The read-only AERA16 reference uses shipping API 34 and VNDK 34. Confirm the installed stock vendor's VNDK before finalizing the target value.
3. **Do not copy TWRP16 boot-image geometry blindly.** The TeamWin `android-14.1` tree specifies a 4096-byte kernel page size, while the TeamWin `android-16` tree specifies 16384 bytes. The A35X AERA bring-up baseline uses boot header v2 and 4096-byte pages. Verify the exact kernel, boot header, DTB/DTBO and known-good A16 image before changing these values. Never enlarge the physical recovery partition to hide image overflow.
4. **Keep the A35X dynamic-partition map grounded in the actual device.** The AERA baseline includes system, vendor, product, odm, vendor_dlkm and system_dlkm. Keep system_dlkm because it is exposed by the device fstab; confirm all logical partition names and sizes against the installed firmware before making any image-builder assumptions.
5. **AERA options are not interchangeable with legacy TW/SHRP flags.** Follow the current AERA 16.0 wiki and reference trees. Keep hardware configuration in BoardConfig/device product files and guarded packaging exports in vendorsetup.sh. Do not assume a TW_* or SHRP_* declaration affects AERA's native interface.
6. **Crypto startup needs a single, audited source of truth.** TEEGRIS must initialize before KeyMint/Gatekeeper/FKeymaster. Check all imported init RC files for duplicate service declarations or triggers. Do not remove any of these services; resolve duplication by verified service ownership and ordering.
7. **The USB init replacement needs a full trigger audit.** AERA's current USB RC is much larger than the minimal TWRP14/16 companion RC. Verify the controller, FunctionFS endpoints, configfs ownership, adb readiness and gadget state transitions. Do not combine both sets of triggers without proving they are complementary.
8. **The current README is stale.** It describes a documentation-only repository although the current tree contains a substantial device configuration and binary payload. Update its status and provenance statements after the actual tree is audited.

## GSI MANAGER — intended A35X Home application

AERA Home is a native plugin launcher. Host API 2 plugins can contribute a native AERA-rendered page with bounded declarative UI messages; the plugin does not draw a separate foreign interface. The intended Home entry is one A35X-only app named **GSI MANAGER**. Its page acts as the submenu for the tools below. Keep the existing Root Manager where AERA already places it; do not duplicate it.

Planned modules:

- **GSI Import & Inspector:** choose an image through AERA's file picker; verify SHA-256; inspect image format, architecture, Android release/API, VNDK and properties before accepting it.
- **Partition & Super Inspector:** read-only inventory of physical/logical partitions, sizes, free space, filesystem types and metadata. Require an explicit review/confirmation for any later write operation.
- **ROM Customizer:** stage optional packages and Samsung compatibility changes against a copied working image, not the active system. Validate Android/API/ABI, space, file ownership, permissions and SELinux contexts.
- **Samsung Compatibility:** compare framework/vendor interfaces, HALs, libraries, init services, VINTF and SELinux requirements while retaining the installed Samsung vendor.
- **Root & Boot Tools:** expose separate Magisk and KernelSU paths, image inspection, manual patching and backup/restore. Preserve the existing manual-only behavior of postrecoveryboot utilities; never auto-write boot.
- **ROM Builder & Export:** rebuild only selected working images, verify output integrity and produce a manifest/change log.
- **Snapshots & Rollback:** record the base image, staged modifications, boot image copies, partition map and checksums. Rollback is a user-confirmed restore, never an automatic format or wipe.

GSI is a system base for experimentation, not DSU. The installed Samsung vendor remains the hardware base. A GSI may also require product, system_ext or other logical partitions; the manager must inspect dependencies instead of assuming every ROM is a single system.img. EROFS/EXT4 conversion requires extraction and rebuilding with metadata, ownership, permissions, SELinux contexts and size constraints preserved; it is not a filesystem-label toggle.

### Plugin integration gate

AERA Host API 2 workers run as root with recovery's access to devices and mounted partitions. Treat every plugin operation as privileged. Validate paths, image metadata, target partition identity, image size, free space and hashes; use read-only inspection by default; stage changes away from active partitions; and require a trusted AERA confirmation before every destructive operation.

AERA's public plugin store verifies packages against its project signing key. Do not weaken or bypass that trust policy. Before shipping a private A35X-only plugin, determine the supported preinstalled/bundled-plugin path or obtain an authorized signing/distribution route. If a core change is required, isolate it in a separate AERA core fork/branch and keep the device tree changes independent.

## Emergency Mode — boot-failure protection

Separate the **trigger** from the **recovery UI**:

- The AERA Emergency page can inspect boot reason, recovery logs, kernel/pstore evidence where available, filesystem state, logical partition metadata, image hashes and known A35X snapshots.
- It can offer reversible repair plans for review, such as restoring a selected known-good image or reverting a selected GApps/ROM customization snapshot.
- It must never wipe or format userdata, erase encryption metadata, alter the bootloader, or restore anything without explicit confirmation.

A recovery-side page cannot independently detect three failed Android boots if the bootloader never transfers control to recovery. Android Rescue Party covers selected userspace crash loops, not every early kernel/boot failure. A custom three-attempt counter would need a reliable ROM-side early-boot marker and a success checkpoint, or verified Samsung bootloader support. Failures before that marker executes remain outside an Android-only detector's reach.

Therefore, implement read-only Emergency diagnostics and snapshot-based manual repair first. Do not enable automatic reboot-to-recovery or automatic rollback until the A35X bootloader behavior, persistent marker location, reboot-reason semantics and false-positive handling have been proven. Do not write to `misc` until its format and ownership are verified.

## Validation gates

1. Confirm the AERA manifest/core revision and build target in a fresh shell with `AERA_BUILD_DEVICE=a35x` set before sourcing envsetup.
2. Finish the product/build-file audit and static checks before compiling.
3. Inspect the resulting recovery image, ramdisk contents, image size, boot header, kernel, DTB and DTBO before any device test.
4. Validate boot, display, touch, USB/ADB, MTP, storage and logs separately.
5. Validate FBE/metadata decryption separately with the exact stock firmware and a device with a configured lock credential.
6. Test GSI operations against disposable image files and a simulated partition map before permitting device writes.
7. Test Emergency diagnostics and restore plans with synthetic failed-boot markers and verified snapshots before enabling any automatic trigger.

Current status: comparison and architecture audit in progress; no AERA image has been built or boot-tested from this repository.


## Implementation progress on `aera-16.0-work`

### Device-tree corrections already staged

- Added `aera_a35x.mk` and inherited it from `device.mk`; aligned the makefile traversal with current AERA device-tree examples.
- Corrected `PRODUCT_SHIPPING_API_LEVEL` and `BOARD_SHIPPING_API_LEVEL` to 34, consistent with the A35X launch platform.
- Kept `PRODUCT_TARGET_VNDK_VERSION := 33` provisionally. No actual `ro.vndk.version` value has been supplied from the installed U4 vendor, so this must be checked before calling the build configuration final.
- Rebased BoardConfig settings on the AERA16 reference while preserving the A35X 4 KiB kernel page size, boot header v2, known recovery image limit and LZ4-disabled ramdisk setting. The dynamic logical partition list now includes `system_dlkm`.
- Removed the hardcoded 2099 security patch placeholder and the stale fixed vendor patch value. The secure services must use the real OS/security-patch properties of the installed ROM.
- Enabled AERA's existing Root Manager through its guarded device-specific packaging option; no second Root Manager page was added.
- Corrected TEEGRIS initialization ordering: the TEE RC import now occurs after the A35X `/dev/block/by-name` symlinks are created. EFS mounts are non-blocking. KeyMint, Gatekeeper and FKeymaster now have one explicit, disabled-until-ready service definition and start only after TEEGRIS/TEE-TS readiness.
- Removed duplicate vendor init service RC declarations for TEEGRIS, KeyMint, Gatekeeper and FKeymaster while preserving the service binaries and the separate PA/TUI RC files. FKeymaster's service declaration is retained in the ordered recovery RC.
- Moved `extract_ta.sh` from `/vendor/bin` to executable `/sbin/extract_ta.sh`, so mounting the real vendor over `/vendor` cannot hide the validator.

### Native Home apps now have a source prototype

- Added a shared Host API 2 worker source and manifests for **GSI MANAGER** and **EMERGENCY MODE**.
- Added a cross-build/packaging script that uses the AERA AArch64 musl sysroot and creates the verified `AERAWEB1` runtime payloads.
- Added an init action to seed the two locally bundled packages into `/tmp/aera/plugins` after AERA mounts its tmpfs. The Home plugin grid can then discover them without changing the shared recovery core.
- Both apps are intentionally read-only in this prototype. GSI image inspection checks the image header, file size and SHA-256; partition/super inventory and Samsung service checks are read-only. Emergency Mode reports boot properties, pstore, filesystem mount/free-space state, secure-service status and recovery-log presence.
- ROM customization, GApps injection, EROFS/EXT4 rebuilding, image export, snapshot creation/restoration, boot patching, automatic rollback and bootloop-triggered reboot remain disabled or informational. No write-to-block-device, format, wipe or reboot command is present in the worker source.
- AERA runs Host API 2 workers as root without a sandbox. The current source therefore stays deliberately narrow. The local packages will be labelled Unofficial by AERA; no signature policy or project signing key is changed.

### Still required before a recovery build can be called ready

1. Build both plugin workers using `bash device/samsung/a35x/plugins/build_plugins.sh` in the synced AERA16 tree. The source has not yet been cross-compiled.
2. Confirm the actual `ro.vndk.version` and `ro.vendor.api_level` from the installed U4 Android 15 system; update the provisional VNDK target only from those values.
3. Verify the A35X brightness sysfs path and maximum range against the known-good A16 recovery or a live read-only sysfs listing.
4. Run the AERA build and inspect the final ramdisk to confirm the two runtime packages and init copy action are present. No recovery image has been built or tested from this branch yet.
5. Static-check the final merged init RC import order, TEE service declarations, USB gadget triggers, fstab, and image size before any device test.


## Additional fstab review

The current AERA fstab matches the separate AERA16 A35X reference and deliberately mounts EFS through the ordered TEE init rather than starting it directly from fstab. Compared with TeamWin14/16, it also includes both EROFS and EXT4 fallbacks for the logical partitions and includes `system_dlkm`.

The original AERA fstab had two removable-storage entries in the wrong source/mount-point order. Prior A35X recovery logs confirmed that the old `external_sd` line was parsed as an invalid block device, and the previous working TWRP flags identified the actual removable sources. The work branch now uses:

- `/dev/block/mmcblk0p1 /external_sd auto ...` for the microSD card, matching the previous TWRP removable-media definition.
- `/dev/block/sdf1 /usb-otg auto ...` for the USB-OTG device.

Neither entry uses a blocking `wait` flag, so missing removable media cannot hold recovery startup. These are based on the prior A35X recovery observations and still need a mount test in the AERA image. The AERA fstab does not declare `keydata` or `keyrefuge`; do not add guessed partition names without a verified PIT/by-name listing.

The TEE init intentionally creates the standard KeyMint/TEE runtime directories under `/data/vendor` and the EFS DAK directory, then applies their expected ownership/contexts. These are narrowly scoped vendor-service setup operations; they are not a userdata format, wipe or image restore. The GSI/Emergency plugin workers themselves remain read-only.


The A35X USB gadget controller is explicitly set to `13200000.dwc3` in the replacement USB RC, matching the value observed in the prior recovery property dump. ADB/MTP/fastbootd still require independent testing in the AERA image.


### Legacy image-build rule

The root-level Android 12.1/TWRP `mkbootimg.mk` was not referenced by the active AERA device product files and was absent from the AERA16 reference tree. It has been moved to `docs/legacy/mkbootimg_android12.1.mk` so it cannot accidentally override AERA 16.0 recovery-image packaging. The active tree keeps only the device-specific `BOARD_MKBOOTIMG_ARGS` and partition geometry.

The prior A35X recovery property dump reports `ro.hardware=s5e8835`, confirming that `init.recovery.s5e8835.rc` is the matching device-init filename. The same recovery evidence reports the USB controller as `13200000.dwc3`; both values are reflected in the working branch.
