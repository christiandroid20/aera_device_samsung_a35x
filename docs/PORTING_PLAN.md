# Galaxy A35 AERA bring-up plan

## Scope

Target: Samsung Galaxy A35 5G, SM-A356E, device family `a35x`.

First platform target: AERA 16.0. The first kernel candidate is the matching Android 15 stock firmware kernel and its associated boot components. The Android version used to build the recovery and the Android version installed on the phone are separate compatibility dimensions.

## Phase 0 — establish a reproducible baseline

- Pin the AERA manifest branch/tag and record the exact manifest revision.
- Record the exact Samsung firmware build used for testing.
- Preserve the matching stock kernel image, DTB, DTBO and any required modules as local test inputs.
- Record hashes and provenance for every binary input.
- Keep proprietary inputs outside this public repository unless redistribution is authorized.

## Phase 1 — device configuration

- Identify the AERA device/product integration points from the pinned upstream source.
- Translate only verified hardware facts from the existing A35 recovery tree.
- Re-check boot image header, recovery placement, partition layout, dynamic partition metadata and fstab against the target firmware.
- Confirm whether the target uses standalone recovery, recovery-as-boot or vendor_boot packaging before defining image targets.
- Add init services and recovery permissions only when supported by device evidence.

## Phase 2 — first boot test

Use the Android 15 stock kernel baseline with its matching DTB/DTBO and required vendor modules. Do not combine components from different firmware releases.

Validation order:
1. Image packaging and header inspection.
2. Recovery boot without modifying userdata.
3. Display and orientation.
4. Touch input.
5. ADB and USB connection.
6. Correct block-device and partition discovery.
7. Read-only inspection of metadata and userdata.
8. Logs for KeyMint, Gatekeeper and TEEGRIS initialization.

A boot animation or recovery UI alone is not proof that all hardware and storage paths work.

## Phase 3 — Android 15 and Android 17 firmware testing

Test firmware compatibility independently and record exact firmware identifiers. Do not assume that a kernel which boots one firmware release will boot another. Android 17 support is a test objective, not a claim of current compatibility.

## Phase 4 — custom kernel decision

Only start a custom kernel build if repeatable evidence shows that:
- the stock kernel cannot boot the recovery image with correct packaging;
- required device drivers/configuration are missing; or
- a specific kernel-side incompatibility cannot be addressed in the device tree or recovery configuration.

If required, keep kernel sources, defconfig, patches, toolchain and build instructions in a separate kernel repository. Do not replace a known-good stock baseline until the custom image is independently validated.

## Data and encryption safety

- Never format, wipe, or run a write-mode filesystem repair on userdata during bring-up.
- Do not infer filesystem type or corruption from a failed mount attempt alone.
- Treat FBE decryption as a separate milestone requiring compatible KeyMint, Gatekeeper, TEEGRIS trusted applications, vendor libraries and recovery integration.
- Report decryption as working only after /data and user storage are mounted and readable without destructive operations.

## Current status

This repository currently contains planning documentation only. Product makefiles, BoardConfig, fstab, init scripts and AERA-specific integration remain pending source inspection and validation.
