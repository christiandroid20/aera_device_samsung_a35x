#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREBUILT="$ROOT/prebuilt"
MODE="${1:---compile-only}"
EXPECTED_IMAGE_SHA256="7617639544b7be8c8209cac9644553ba795e7b27d5f51cc0fad2505a976349e1"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
note() { printf 'INFO: %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }

[[ "$MODE" == "--compile-only" || "$MODE" == "--device-test" ]] || fail "Usage: $0 [--compile-only|--device-test]"

for f in Image dtb.img dtbo.img; do
  [[ -s "$PREBUILT/$f" ]] || fail "Missing or empty prebuilt/$f"
done

actual_sha="$(sha256sum "$PREBUILT/Image" | awk '{print $1}')"
[[ "$actual_sha" == "$EXPECTED_IMAGE_SHA256" ]] || fail "prebuilt/Image SHA-256 mismatch. Expected $EXPECTED_IMAGE_SHA256, got $actual_sha"

FSTAB="$ROOT/recovery.fstab"
[[ -s "$FSTAB" ]] || fail "recovery.fstab is missing or empty"

if grep -q 'PROVISIONAL ONLY' "$FSTAB"; then
  if [[ "$MODE" == "--device-test" ]]; then
    fail "recovery.fstab is still provisional. Replace it with the matching firmware fstab before any device test."
  fi
  warn "recovery.fstab is provisional. This mode is compile-only; do not flash or boot this image on the phone."
fi

if [[ "$MODE" == "--device-test" ]]; then
  [[ -s "$PREBUILT/vendor_boot.img" ]] || fail "Missing prebuilt/vendor_boot.img; inspect matching vendor ramdisk before device-test readiness."
  warn "This script checks file presence/provenance only. It does not validate partition sizes, image packaging, DTB compatibility, or FBE decryption."
else
  warn "Compile-only preflight does not authorize flashing, booting, or writing to device partitions."
fi

note "Kernel SHA-256 verified: $actual_sha"
note "Required prebuilt files are present."
note "Mode: $MODE"
