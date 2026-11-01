# Supplied SM-A356E boot image audit

## Input

- Archive: `boot.img_SM-A356E_OS15_A356EXXU4BYDC_ZTO.zip`
- Archive member: `boot.img.lz4`
- Decompressed image size: 67,108,864 bytes (64 MiB)
- Boot magic: `ANDROID!`

## Parsed Android boot header

| Field | Value |
|---|---:|
| Header version | 4 |
| Header size | 1584 |
| Page size | 4096 |
| Kernel size | 38,246,912 bytes |
| Ramdisk size | 0 bytes |
| OS version field | Android 13.0.0 / April 2025 metadata |

The `os_version` field is header metadata and is not conclusive proof of the Android framework release of the complete firmware. Verify the firmware package and companion images before labeling the complete set Android 15.

## Kernel extraction

The kernel payload begins after the 4096-byte header page and is 38,246,912 bytes. It was compared against the separately extracted `a35x_A356EXXU4BYDC_kernel.Image`; the files are byte-for-byte identical.

SHA-256:

```
7617639544b7be8c8209cac9644553ba795e7b27d5f51cc0fad2505a976349e1
```

## Consequences for the AERA device tree

- Set the observed boot header baseline to v4 (pending confirmation against the recovery image format expected by the target partition).
- Keep the extracted kernel as a local prebuilt; do not commit firmware binaries without redistribution authorization.
- The boot image contains no ramdisk, so inspect matching `vendor_boot.img` for vendor ramdisk fragments and init/fstab data.
- Obtain matching DTBO and determine whether DTB is appended to the kernel or separately packaged.
- Do not infer FBE support from compile flags or from the presence of KeyMint/Gatekeeper files.
- Do not test the provisional Android 13-derived recovery fstab on userdata.
