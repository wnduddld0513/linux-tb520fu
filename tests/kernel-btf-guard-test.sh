#!/usr/bin/env bash
# The TB520FU BTF gate in packages/kernel/scripts/build-kernel.sh. A TB520FU
# build must refuse an effective config without CONFIG_DEBUG_INFO_BTF, refuse a
# missing pahole and refuse pahole < 1.26 before it compiles, must fail when the
# built vmlinux has no .BTF, and must record the pahole version plus the .BTF
# digest. Other devices must keep building, without pahole.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_SCRIPT="$ROOT/packages/kernel/scripts/build-kernel.sh"
BASH_BIN="$(command -v bash)"
kernel_version=7.2.6
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

stub() { # stub <file> <script line>...
    local file="$1"
    shift
    {
        echo '#!/usr/bin/env bash'
        echo 'set -eu'
        printf '%s\n' "$@"
    } > "$file"
    chmod +x "$file"
}

# The script under test gets a PATH holding only this directory, so a real
# pahole or ccache on the host cannot change the outcome.
sandbox() { # sandbox <dir>
    local bin="$1" tool real
    mkdir -p "$bin"
    for tool in awk basename bash cat cp cut dirname grep head ls mkdir mktemp \
        nproc rm sed sha256sum tar tee wc; do
        real="$(command -v "$tool" || true)"
        [ -n "$real" ] || fail "this test needs ${tool} on PATH"
        ln -sf "$real" "$bin/$tool"
    done
    # Pin the cross-compiling branch so the test behaves the same on any host.
    stub "$bin/uname" 'echo x86_64'
    stub "$bin/aarch64-linux-gnu-gcc" 'exit 0'
    # make: kernelrelease for KVER, and the artifacts the build/stage steps copy.
    stub "$bin/make" \
        'for arg in "$@"; do' \
        "    if [ \"\${arg}\" = kernelrelease ]; then echo ${kernel_version}; exit 0; fi" \
        'done' \
        'printf '\''make %s\n'\'' "$*" >> "${TEST_LOG}"' \
        'mkdir -p arch/arm64/boot/dts/qcom' \
        ': > arch/arm64/boot/Image' \
        ': > arch/arm64/boot/dts/qcom/sm8650-lenovo-tb520fu.dtb' \
        ': > vmlinux'
    # zstd must drain tar's stdin and leave the archive it was asked for.
    stub "$bin/zstd" \
        'out=' \
        'while [ "$#" -gt 0 ]; do' \
        '    case "$1" in' \
        '        -o) out="$2"; shift 2 ;;' \
        '        *) shift ;;' \
        '    esac' \
        'done' \
        'cat > /dev/null' \
        '[ -n "${out}" ]' \
        ': > "${out}"'
}

# build-kernel.sh derives every path from its own location, so a fake package
# tree can drive it without kernel sources.
package() { # package <dir>
    local pkg="$1"
    mkdir -p "$pkg/scripts" "$pkg/dts" "$pkg/patches" "$pkg/config"
    cp "$BUILD_SCRIPT" "$pkg/scripts/build-kernel.sh"
    printf 'VERSION=%s\n' "$kernel_version" > "$pkg/BASE.env"
    : > "$pkg/patches/series"
    printf '/ { model = "TB520FU test fixture"; };\n' > "$pkg/dts/sm8650-lenovo-tb520fu.dts"
    printf '/ { };\n' > "$pkg/dts/sm8650-lenovo-tb520fu.dtsi"
}

case_env() { # case_env <name>; sets case_dir, pkg and the fake build tree
    case_dir="$WORK/$1"
    pkg="$case_dir/pkg"
    local src="$case_dir/build/linux-${kernel_version}"
    mkdir -p "$src/scripts/kconfig"
    : > "$case_dir/build/linux-${kernel_version}.tar.xz" # FAST=1 never extracts it
    sandbox "$case_dir/bin"
    stub "$src/scripts/kconfig/merge_config.sh" 'cp "$2" "$1"'
    package "$pkg"
}

fragment() { # fragment <line>...: the effective .config this case resolves to
    printf '%s\n' "$@" > "$pkg/config/armada-kernel.config.overrides"
}

run_build() { # run_build: FAST=1 build inside the case sandbox
    set +e
    PATH="$case_dir/bin" \
        FAST=1 \
        WORK_DIR="$case_dir/build" \
        OUT_DIR="$case_dir/out" \
        TEST_LOG="$case_dir/make.log" \
        "$BASH_BIN" "$pkg/scripts/build-kernel.sh" \
        > "$case_dir/stdout" 2> "$case_dir/stderr"
    status=$?
    set -e
}

staged_metadata() {
    echo "$case_dir/build/staging-${kernel_version}/lib/modules/${kernel_version}/.armada-source"
}

expect_failure() { # expect_failure <stderr pattern>
    [ "$status" -ne 0 ] || fail "$case_dir: build succeeded, expected a failure"
    grep -q "$1" "$case_dir/stderr" || {
        cat "$case_dir/stderr" >&2
        fail "$case_dir: stderr does not mention '$1'"
    }
}

expect_no_build() {
    if grep -q Image "$case_dir/make.log" 2>/dev/null; then
        fail "$case_dir: the gate failed only after compiling"
    fi
}

expect_build() {
    grep -q Image "$case_dir/make.log" 2>/dev/null || fail "$case_dir: Image was never built"
}

# 1. TB520FU without CONFIG_DEBUG_INFO_BTF. No pahole either, so a gate that
#    checked the toolchain first would report pahole instead.
case_env no-debug-info-btf
fragment 'CONFIG_BACKLIGHT_TB520FU_KTZ8866=y'
run_build
expect_failure 'CONFIG_DEBUG_INFO_BTF'
expect_no_build

# 2. TB520FU with CONFIG_DEBUG_INFO_BTF but no pahole at all
case_env pahole-missing
fragment 'CONFIG_BACKLIGHT_TB520FU_KTZ8866=y' 'CONFIG_DEBUG_INFO_BTF=y'
run_build
expect_failure 'pahole'
expect_no_build

# 3. TB520FU with the pahole (1.25) that produces the unusable BTF
case_env pahole-old
fragment 'CONFIG_BACKLIGHT_TB520FU_KTZ8866=y' 'CONFIG_DEBUG_INFO_BTF=y'
stub "$case_dir/bin/pahole" 'echo v1.25'
run_build
expect_failure 'older than 1.26'
expect_no_build

# 4. TB520FU with pahole 1.26: the .BTF is dumped, hashed and recorded
case_env recorded
fragment 'CONFIG_BACKLIGHT_TB520FU_KTZ8866=y' 'CONFIG_DEBUG_INFO_BTF=y'
stub "$case_dir/bin/pahole" 'echo v1.26'
stub "$case_dir/bin/aarch64-linux-gnu-objcopy" \
    'out=' \
    'for arg in "$@"; do' \
    '    case "${arg}" in' \
    '        .BTF=*) out="${arg#.BTF=}" ;;' \
    '    esac' \
    'done' \
    '[ -n "${out}" ]' \
    "printf 'BTF fixture\n' > \"\${out}\""
run_build
[ "$status" -eq 0 ] || {
    cat "$case_dir/stderr" >&2
    fail "recorded: build failed"
}
expect_build
metadata="$(staged_metadata)"
expected_digest="sha256:$(printf 'BTF fixture\n' | sha256sum | cut -d' ' -f1)"
grep -qx 'BTF: vmlinux .BTF emitted with CONFIG_DEBUG_INFO_BTF=y, pahole v1.26' "$metadata" \
    || fail "recorded: .armada-source does not record the pahole version"
grep -qx "BTF digest: ${expected_digest}" "$metadata" \
    || fail "recorded: .armada-source does not record the .BTF digest"

# 5. TB520FU whose vmlinux carries no .BTF: fail after the build, stage nothing
case_env no-btf-section
fragment 'CONFIG_BACKLIGHT_TB520FU_KTZ8866=y' 'CONFIG_DEBUG_INFO_BTF=y'
stub "$case_dir/bin/pahole" 'echo v1.26'
stub "$case_dir/bin/aarch64-linux-gnu-objcopy" 'exit 1'
run_build
expect_failure 'carries no .BTF section'
expect_build
[ ! -e "$(staged_metadata)" ] || fail "no-btf-section: staged a kernel without vmlinux .BTF"

# 6. Any other device: no pahole, no BTF fields, build unchanged
case_env other-device
fragment 'CONFIG_DRM=y' 'CONFIG_DRM_PANEL_NOVATEK_NT36532=y'
run_build
[ "$status" -eq 0 ] || {
    cat "$case_dir/stderr" >&2
    fail "other-device: build failed"
}
expect_build
[ -f "$(staged_metadata)" ] || fail "other-device: .armada-source is missing"
if grep -q BTF "$(staged_metadata)"; then
    cat "$(staged_metadata)" >&2
    fail "other-device: recorded BTF fields for a non-gated build"
fi

# 7. TB520FU identity can also come from the effective localversion
case_env localversion
fragment 'CONFIG_DRM=y' 'CONFIG_LOCALVERSION="-tb520fu"'
run_build
expect_failure 'CONFIG_DEBUG_INFO_BTF'
expect_no_build

# The gate keys off these two fragment lines; keep them from drifting away.
fragment_file="$ROOT/packages/kernel/config/armada-kernel.config.overrides"
grep -qx 'CONFIG_DEBUG_INFO_BTF=y' "$fragment_file" \
    || fail "the kernel fragment no longer enables CONFIG_DEBUG_INFO_BTF"
grep -qx 'CONFIG_BACKLIGHT_TB520FU_KTZ8866=y' "$fragment_file" \
    || fail "the kernel fragment no longer identifies TB520FU"

echo 'Kernel BTF guard tests passed'
