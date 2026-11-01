# Required local firmware inputs

## Kernel currently extracted

The supplied archive `boot.img_SM-A356E_OS15_A356EXXU4BYDC_ZTO.zip` contains
`boot.img.lz4`. Its decompressed Android boot image has a v4 header, 4096-byte
pages, a 38,246,912-byte ARM64 kernel payload and an empty ramdisk.

The extracted kernel was verified byte-for-byte against the boot image payload.

- Expected local filename: `Image`
- Expected SHA-256:
  `7617639544b7be8c8209cac9644553ba795e7b27d5f51cc0fad2505a976349e1`

Copy the separately supplied extracted kernel into this directory as
`Image`, then run:

```bash
sha256sum Image
```

Do not commit proprietary firmware binaries unless redistribution is
authorized. Keep the source archive and exact build ID recorded locally.

## Still required from the same firmware

- `dtbo.img` — matching device tree overlay image;
- `dtb.img` — only if the firmware packages DTB separately; inspect the
  kernel/container before deciding;
- `vendor_boot.img` — required to inspect vendor ramdisk contents because the
  supplied boot image has a zero-length ramdisk;
- matching vendor kernel modules, where needed by recovery.

Never mix Image, DTB, DTBO, vendor_boot or vendor modules from different
firmware builds. The current recovery fstab is provisional and must be replaced
with the matching firmware's fstab before device testing.
