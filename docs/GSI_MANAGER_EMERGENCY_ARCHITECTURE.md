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
