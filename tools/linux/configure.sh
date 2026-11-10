#!/usr/bin/env bash
# shellcheck shell=bash
# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Configures a local Linux build with the CI Linux options (see release-binaries.yml).
# Env: SRC_DIR (default: this checkout), BUILD_DIR (~/lx/build), BUILD_TYPE (RelWithDebInfo),
# QT_DIR (~/lx/qt, Qt from tools/linux/install-deps.sh; falls back to the system Qt),
# CC/CXX (default clang, else gcc). Extra arguments go to cmake.

set -euo pipefail

SRC_DIR=${SRC_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}
BUILD_DIR=${BUILD_DIR:-$HOME/lx/build}
BUILD_TYPE=${BUILD_TYPE:-RelWithDebInfo}
QT_DIR=${QT_DIR:-$HOME/lx/qt}

if [ -z "${CC:-}" ] && command -v clang > /dev/null && command -v clang++ > /dev/null; then
    CC=clang
    CXX=clang++
fi
CC=${CC:-gcc}
CXX=${CXX:-g++}

flags=(
    -G Ninja
    "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
    "-DCMAKE_C_COMPILER=$CC"
    "-DCMAKE_CXX_COMPILER=$CXX"
    -DBUILD_TESTING=OFF
    -DYUZU_TESTS=OFF
    -DYUZU_CMD=ON
    -DYUZU_ROOM=OFF
    -DYUZU_ROOM_STANDALONE=OFF
    -DYUZU_USE_BUNDLED_QT=OFF
    -DYUZU_USE_BUNDLED_SDL3=ON
    -DVulkanHeaders_FORCE_BUNDLED=ON
    -DVulkanUtilityLibraries_FORCE_BUNDLED=ON
    -DENABLE_UPDATE_CHECKER=OFF
    -DLICHII_BUILD_TAG=local
    "-DLICHII_BUILD_PLATFORM=linux-$(uname -m)"
    -DUSE_DISCORD_PRESENCE=OFF
    -DUSE_CCACHE=ON
)

qt_prefix=$(find "$QT_DIR" -maxdepth 4 -path '*/gcc_*64/bin/qmake' 2> /dev/null | sort -V | tail -n 1)
if [ -n "$qt_prefix" ]; then
    flags+=("-DCMAKE_PREFIX_PATH=${qt_prefix%/bin/qmake}")
fi

# lld links the multi-GB debug binary much faster than ld.bfd.
case "$CC" in
    *clang*) command -v ld.lld > /dev/null && flags+=(-DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld) ;;
esac

cmake -S "$SRC_DIR" -B "$BUILD_DIR" "${flags[@]}" "$@"
