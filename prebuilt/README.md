# Required local kernel inputs

The initial AERA build is designed to use the Android 15 stock kernel from the
exact SM-A356E firmware selected for testing.

Place the matching files here, extracted from the same firmware package:

- `Image` — kernel image;
- `dtb.img` — device tree blob, if packaged separately;
- `dtbo.img` — matching DTBO image.

The existing legacy device repository has an empty `prebuilt/Image`
placeholder; it is **not** a usable kernel. Do not start a build until a
non-empty stock Android 15 kernel has been placed here and its source firmware
build/hash recorded.

Never mix Image, DTB, DTBO or vendor modules from different firmware builds.
Do not commit proprietary firmware binaries unless redistribution is
authorized.
