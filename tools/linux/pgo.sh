#!/usr/bin/env bash
# shellcheck shell=bash
# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Release build with the repo's eglantine.profdata, like the CI linux-x86_64-pgo job.
# Needs a clang that can read the profile (CI uses clang-23 from apt.llvm.org); set PGO_LLVM_VERSION
# to the installed major. Env: BUILD_DIR (default ~/lx/build-pgo), JOBS.

set -euo pipefail

PGO_LLVM_VERSION=${PGO_LLVM_VERSION:-23}
SRC_DIR=$(cd "$(dirname "$0")/../.." && pwd)
BUILD_DIR=${BUILD_DIR:-$HOME/lx/build-pgo}
export SRC_DIR BUILD_DIR

test -s "$SRC_DIR/eglantine.profdata"
command -v "clang-$PGO_LLVM_VERSION" > /dev/null || {
    echo "clang-$PGO_LLVM_VERSION not found; install it from apt.llvm.org or set PGO_LLVM_VERSION" >&2
    exit 1
}

profile="-fprofile-use=$SRC_DIR/eglantine.profdata -Wno-backend-plugin -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date"
CC="clang-$PGO_LLVM_VERSION" CXX="clang++-$PGO_LLVM_VERSION" BUILD_TYPE=Release \
    "$(dirname "$0")/configure.sh" \
    "-DCMAKE_EXE_LINKER_FLAGS=-B/usr/lib/llvm-$PGO_LLVM_VERSION/bin -fuse-ld=lld" \
    "-DCMAKE_C_FLAGS=$profile" \
    "-DCMAKE_CXX_FLAGS=$profile"
"$(dirname "$0")/build.sh"
