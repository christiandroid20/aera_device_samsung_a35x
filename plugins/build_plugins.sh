#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")" && pwd)"
DEVICE_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"
AERA_TREE="${AERA_TREE:-$(cd "$DEVICE_ROOT/../../.." && pwd)}"
SYSROOT="$AERA_TREE/prebuilts/build-tools/sysroots/aarch64-unknown-linux-musl"
CLANG="${AERA_CLANG:-}"
if [[ -z "$CLANG" ]]; then
    for candidate in "$AERA_TREE"/prebuilts/clang/host/linux-x86/*/bin/clang; do
        if [[ -x "$candidate" ]]; then CLANG="$candidate"; break; fi
    done
fi
if [[ -z "$CLANG" || ! -x "$CLANG" ]]; then
    echo "AERA clang not found. Set AERA_CLANG or sync AERA 16.0 prebuilts." >&2
    exit 1
fi
if [[ ! -f "$SYSROOT/lib/crt1.o" ]]; then
    echo "AArch64 musl sysroot missing: $SYSROOT" >&2
    exit 1
fi
CLANG_ROOT="$(cd "$(dirname "$CLANG")/.." && pwd)"
BUILTINS="${AERA_BUILTINS:-$(find "$CLANG_ROOT/lib/clang" -path '*/aarch64-unknown-linux-musl/libclang_rt.builtins.a' -print -quit)}"
if [[ ! -f "$BUILTINS" ]]; then
    echo "AArch64 musl compiler builtins not found under $CLANG_ROOT." >&2
    exit 1
fi

WORK="$(mktemp -d "$PLUGIN_ROOT/.build.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

build_one() {
    local id="$1" define="$2"
    local stage="$WORK/$id/stage"
    local packed="$WORK/$id/packed"
    local output="$DEVICE_ROOT/recovery/root/system/etc/aera/plugins/$id"
    mkdir -p "$stage/usr/bin" "$packed" "$output"

    "$CLANG" \
        --target=aarch64-unknown-linux-musl \
        --sysroot="$SYSROOT" \
        -nostdinc -isystem "$SYSROOT/include" \
        -std=c11 -Os -Wall -Wextra -Werror \
        -Wno-unused-function -Wno-unused-const-variable \
        -ffunction-sections -fdata-sections \
        -static -nostdlib -fuse-ld=lld \
        "$SYSROOT/lib/crt1.o" "$SYSROOT/lib/crti.o" \
        -D"$define" "$PLUGIN_ROOT/a35x_aera_plugin.c" \
        -L"$SYSROOT/lib" -lc "$BUILTINS" "$SYSROOT/lib/crtn.o" \
        -Wl,--gc-sections,-s \
        -o "$stage/usr/bin/aera-plugin"

    chmod 0755 "$stage/usr/bin/aera-plugin"
    python3 "$PLUGIN_ROOT/pack.py" "$stage" "$packed"

    python3 - "$PLUGIN_ROOT/$id/plugin.json" "$packed/metadata.json" "$output/plugin.json" <<'PY'
import json
from pathlib import Path
import sys
source = json.loads(Path(sys.argv[1]).read_text())
meta = json.loads(Path(sys.argv[2]).read_text())
source.update({
    "payload_size": meta["compressed"],
    "payload_sha256": meta["sha256"],
    "expanded_size": meta["expanded"],
    "expanded_sha256": meta["expanded_sha256"],
    "member_count": meta["files"],
})
Path(sys.argv[3]).write_text(json.dumps(source, ensure_ascii=False, indent=2) + "\n")
PY
    install -m 0444 "$packed/runtime.xz" "$output/runtime.xz"
    chmod 0444 "$output/plugin.json"
    echo "Prepared AERA RAM plugin: $output"
}

build_one "gsi-manager" "APP_GSI"
build_one "emergency-mode" "APP_EMERGENCY"

echo "Both A35X plugins are staged under recovery/root/system/etc/aera/plugins."
echo "Run this script before the AERA 16.0 recoveryimage build."
