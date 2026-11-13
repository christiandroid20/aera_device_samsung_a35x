#!/sbin/sh
# Read-only diagnostics for Samsung Galaxy A35x SHRP recovery.
# This does NOT run Google Play Integrity and does not alter boot properties.
OUT="/tmp/a35x-recovery-diagnostics.txt"
{
 echo "=== A35x SHRP recovery diagnostics ==="
 echo "Date: $(date 2>/dev/null)"
 echo
 echo "--- Device / build ---"
 for p in ro.product.device ro.product.model ro.product.vendor.device ro.build.fingerprint ro.vendor.build.fingerprint ro.build.version.release ro.build.version.sdk ro.build.version.security_patch ro.vendor.build.security_patch; do
  printf '%s=' "$p"; getprop "$p"
 done
 echo
 echo "--- Verified Boot state (reported values; not modified) ---"
 for p in ro.boot.verifiedbootstate ro.boot.flash.locked ro.boot.vbmeta.device_state ro.boot.veritymode ro.boot.warranty_bit ro.boot.bootloader ro.boot.slot_suffix; do
  printf '%s=' "$p"; getprop "$p"
 done
 echo
 echo "--- Crypto / KeyMint ---"
 for p in ro.crypto.state ro.crypto.type ro.crypto.volume.filenames_mode crypto.ready vendor.TEEGRIS.loaded vendor.tzdaemon; do
  printf '%s=' "$p"; getprop "$p"
 done
 echo
 echo "--- Relevant block devices ---"
 for d in /dev/block/by-name /dev/block/bootdevice/by-name; do
  if [ -d "$d" ]; then echo "[$d]"; ls -l "$d" 2>/dev/null; fi
 done
 echo
 echo "--- Mounts ---"
 cat /proc/mounts 2>/dev/null
 echo
 echo "--- Key services ---"
 for s in tz_service tzts_service vendor.keymint-default vendor.gatekeeper-1-0; do
  echo "$s: $(getprop init.svc.$s)"
 done
 echo
 echo "--- Data / metadata status ---"
 ls -ld /data /metadata /metadata/vold /metadata/vold/metadata_encryption 2>&1
 echo
 echo "--- Recent crypto / storage kernel messages ---"
 dmesg 2>/dev/null | grep -iE 'keymint|gatekeeper|tee|trustzone|vold|fscrypt|fbe|metadata|userdata|ufs|f2fs|ext4' | tail -n 160
 echo
 echo "NOTE: Play Integrity is an Android/Google Play services attestation."
 echo "It cannot be evaluated from recovery. This report captures only"
 echo "recovery-visible boot, crypto, storage and TEE diagnostics."
} > "$OUT" 2>&1
cat "$OUT"
echo
echo "Saved report: $OUT"
