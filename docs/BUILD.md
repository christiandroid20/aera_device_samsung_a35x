# Building AERA 16.0 for Galaxy A35

## 1. Sync AERA 16.0

Initialize the upstream AERA manifest on branch `aera-16.0` and sync it using
the official AERA build documentation:
https://aera-recovery.com/wiki/

## 2. Add the local manifest

Copy `manifests/a35x.xml` from this repository into the source tree's
`.repo/local_manifests/a35x.xml`, then sync again.

The manifest checks out:
- this device tree at `device/samsung/a35x`;
- the existing vendor source at `vendor/samsung/a35x`.

The vendor repository is included for source inspection only. Its generated
makefiles are not inherited by the recovery product because that snapshot is
not proven to match the target firmware.

## 3. Current boot image evidence

The supplied archive `boot.img_SM-A356E_OS15_A356EXXU4BYDC_ZTO.zip` contains
`boot.img.lz4`. Decompression produced a 64 MiB Android boot image with:

- boot magic: `ANDROID!`;
- boot header version: 4;
- page size: 4096 bytes;
- kernel payload: 38,246,912 bytes;
- ramdisk payload: 0 bytes;
- kernel SHA-256:
  `7617639544b7be8c8209cac9644553ba795e7b27d5f51cc0fad2505a976349e1`.

The extracted kernel was byte-for-byte identical to the kernel payload in the
boot image. The boot header's `os_version` field decodes to Android 13.0.0 and
April 2025 patch metadata. This field is not sufficient by itself to identify
the Android framework release of the complete firmware. Confirm provenance
using the firmware package metadata and matching vendor_boot/vendor files.

The kernel binary is a local prebuilt input and is intentionally not committed
to this repository. Place the extracted file at:

```
device/samsung/a35x/prebuilt/Image
```

Then verify its hash:

```bash
sha256sum device/samsung/a35x/prebuilt/Image
```

Expected SHA-256:
`7617639544b7be8c8209cac9644553ba795e7b27d5f51cc0fad2505a976349e1`

## 4. Required matching firmware inputs still missing

Obtain these from the exact same SM-A356E firmware package/build as the boot
image; do not mix releases:

- `vendor_boot.img` — inspect vendor ramdisk fragments, fstab/init files and
  vendor ramdisk version. The supplied boot image has no ramdisk.
- `dtbo.img` — required matching overlay table.
- DTB — determine whether it is appended to the kernel or supplied separately;
  populate `prebuilt/dtb.img` only after locating and validating it.
- Android 15 `fstab.s5e8835` (or the exact fstab used by the target firmware).
- Vendor kernel modules and matching vendor ramdisk dependencies, if recovery
  needs them for display, touch, storage, USB or crypto.
- Exact partition map / recovery target and image packaging details.

The current `recovery.fstab` is provisional and derived from an Android 13
vendor snapshot. It is NOT approved for device testing. Replace it only after
extracting and reviewing the fstab from the matching firmware. Keep userdata
read-only during first bring-up.

Do not copy the Android 13 vendor blobs into this Android 15 bring-up blindly.
The existing vendor repository reports build `A356EXXS7CZA4`, Android 13,
SDK 33; it is not a verified match for `A356EXXU4BYDC`.

## 5. Configure and compile

Once the matching DTB/DTBO and firmware-derived fstab are available, place the
prebuilt inputs locally, review all partition sizes/targets, then run:

```bash
export AERA_BUILD_DEVICE=a35x
source build/envsetup.sh
lunch twrp_a35x-bp2a-eng
mka -j"$(nproc)" recoveryimage
```

A compile-only smoke test can be used earlier to expose product/Soong errors,
but it must not be treated as a valid device image while required prebuilt
inputs or fstab remain provisional. Do not flash such an image.

## 6. Local preflight

After copying the extracted kernel to `prebuilt/Image` and adding the matching
`dtb.img` and `dtbo.img`, run:

```bash
bash tools/preflight.sh --compile-only
```

This checks the three local prebuilt files and verifies the kernel SHA-256.
It warns that the current fstab is provisional and that the resulting build
must not be flashed or booted.

After the matching firmware fstab and vendor_boot audit are complete, run:

```bash
bash tools/preflight.sh --device-test
```

This is only a file/provenance gate, not a substitute for image-header,
partition-size, DTB compatibility or hardware validation.

## 7. Bring-up gates

1. Build-system/product configuration resolves without missing target errors.
2. Recovery image packaging uses the verified boot header and partition
   metadata.
3. Image boots to AERA UI without rebooting.
4. Display, touch, ADB and USB are functional.
5. Physical partitions and logical super metadata can be inspected safely.
6. `/metadata` and `/data` are inspected read-only; no formatting, wiping or
   write-mode filesystem repair.
7. FBE decryption is a separate milestone requiring matching KeyMint,
   Gatekeeper, TEEGRIS/TA and vendor runtime dependencies.

Successful compilation or UI boot does not prove data decryption.
