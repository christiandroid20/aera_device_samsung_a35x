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

The vendor repository is currently included for source inspection; its
generated makefiles are not yet inherited by the recovery product.

## 3. Supply the Android 15 stock kernel

Extract `Image`, `dtb.img` and `dtbo.img` from one exact SM-A356E Android 15
firmware build and place them in `device/samsung/a35x/prebuilt/`.

The current legacy `prebuilt/Image` placeholder is zero bytes and must be
replaced locally. Record the firmware build ID and hashes before compiling.

## 4. Configure and build

```bash
export AERA_BUILD_DEVICE=a35x
source build/envsetup.sh
lunch twrp_a35x-bp2a-eng
mka -j"$(nproc)" recoveryimage
```

Do not flash an image merely because compilation succeeds. First inspect the
image header and partition target, then test boot with a known-good return path.

## Current limitations

- The recovery fstab is an initial firmware-derived read-only bring-up version.
- Kernel packaging offsets and exact recovery placement still require
  confirmation from the target firmware.
- The vendor repository has not yet been converted into a minimal AERA
  recovery runtime bundle.
- Successful compilation or UI boot does not prove FBE decryption.
