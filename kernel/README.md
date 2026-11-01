# Kernel baseline

The first AERA bring-up attempt is intended to reuse the **Android 15 stock kernel from the exact SM-A356E firmware selected for testing**.

Keep the following components matched to that same firmware release:

- kernel Image (or the kernel payload extracted from the relevant boot container);
- DTB;
- DTBO;
- vendor kernel modules, when required;
- boot image header/packaging metadata.

Do not assume that a generic Android 15 kernel, another Galaxy model's kernel, or a kernel from a different A35 firmware build is interchangeable.

No kernel source, binary, defconfig or flashable image is included in this directory yet. If custom kernel work becomes necessary, it should be reproducible and preferably live in a dedicated repository, with this device tree documenting the exact revision and build inputs.
