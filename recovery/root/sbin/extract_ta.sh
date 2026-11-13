#!/sbin/sh
#
# Samsung TEEGRIS TA validation for Galaxy A35x recovery.
# This script lives in the recovery ramdisk (/sbin), not /vendor: the real
# vendor logical partition may be mounted over /vendor and hide ramdisk files.
#

VENDOR="/vendor"
TEE="$VENDOR/tee"
OK=1
attempt=0

# Never trust the recovery ramdisk's bundled /vendor directory. The current
# SM-A356E U4 layout has been observed as dm-4; fail closed if it differs.
setprop crypto.ready 0
setprop vendor.TEEGRIS.loaded false

vendor_is_real_mounted() {
    awk '$3 == "254:4" && $5 == "/vendor" { found=1 } END { exit !found }' /proc/self/mountinfo
}

# Wait for the real logical vendor mount. This is a oneshot service and does
# not block init or the recovery UI.
while [ "$attempt" -lt 90 ] && ! vendor_is_real_mounted; do
    sleep 1
    attempt=$((attempt + 1))
done

if ! vendor_is_real_mounted; then
    echo "E:extract_ta: expected real vendor dm-4 is not mounted at /vendor; refusing ramdisk TA files" >> /tmp/recovery.log
    exit 1
fi

if [ ! -d "$TEE" ]; then
    echo "E:extract_ta: /vendor/tee missing on mounted dm-4" >> /tmp/recovery.log
    exit 1
fi

check_required() {
    source_file="$1"
    if [ ! -s "$source_file" ]; then
        echo "E:extract_ta: required TEE file missing: $source_file" >> /tmp/recovery.log
        OK=0
        return 1
    fi
    return 0
}

# Crypto Manager Driver
check_required "$TEE/driver/00000000-0000-0000-0000-53626f786476"
# ICCC Driver
check_required "$TEE/driver/00000000-0000-0000-0000-494363447256"
# KeyMint TA
check_required "$TEE/00000000-0000-0000-0000-4b45594d5354"
# TZ_ICCC TA
check_required "$TEE/00000000-0000-0000-0000-0053545354ab"
# Gatekeeper TA
check_required "$TEE/00000000-0000-0000-0000-474154454b45"

if [ "$OK" -ne 1 ]; then
    echo "E:extract_ta: TEE validation incomplete; crypto.ready remains 0" >> /tmp/recovery.log
    exit 1
fi

echo "I:extract_ta: required A35x TEE files found on mounted vendor dm-4" >> /tmp/recovery.log
setprop vendor.TEEGRIS.loaded true
setprop crypto.ready 1
exit 0
