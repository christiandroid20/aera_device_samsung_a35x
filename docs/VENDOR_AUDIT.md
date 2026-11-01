# Existing vendor repository audit

Source repository: https://github.com/christiandroid20/vendor_samsung_a35x
Branch inspected: `main`

## Confirmed useful source data

- `proprietary/vendor/etc/fstab.s5e8835` identifies the A35 storage layout.
- The stock fstab identifies `/metadata` as ext4 and `/data` as F2FS.
- The userdata entry uses FBE with AES-256-XTS/CBC, inlinecrypt, wrapped-key and metadata-encryption options.
- Vendor init snippets exist for KeyMint and Gatekeeper.
- The proprietary file manifest lists Samsung TEE, KeyMint, Gatekeeper and other vendor components.

## Build integration status

The vendor repository is **not yet a ready-to-inherit AERA vendor product**:
- its current `Android.mk` is an empty generated wrapper;
- `a35x-vendor.mk` defines a `PRODUCT_SOURCE_FILES` list rather than a verified set of recovery copy rules or installable modules;
- the presence of a proprietary file manifest does not prove that every listed binary is present, correct for the selected firmware, or suitable for a recovery ramdisk.

For that reason, this AERA device product does not blindly inherit the vendor makefile or copy the complete vendor tree into recovery.

## Next vendor integration work

1. Record the exact source firmware build and compare it with the handset's installed build.
2. Inventory the actual tracked proprietary files and hashes.
3. Identify the minimal recovery runtime closure for TEEGRIS, KeyMint and Gatekeeper.
4. Check ELF dependencies, linker namespaces, init service requirements, SELinux labels and TA loading paths.
5. Integrate only required, redistributable files into the recovery ramdisk.
6. Test decryption separately from recovery boot and never format userdata as a troubleshooting step.

The first AERA milestone is boot/display/touch/ADB and safe read-only partition inspection. FBE decryption remains a separate unverified milestone.
